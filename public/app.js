import {
  CONTROL_DEFINITIONS,
  createDefaultState,
  parseControlValue,
} from "./app/config/controls.js";
import {
  DEFAULT_GENERATOR_CONFIG,
  FAN_AIR_BROWN_MIX,
  FAN_RUMBLE_FILTERS,
  fanAirLevel,
  fanHumFrequency,
  fanHumLevel,
  fanRumbleLevel,
  greenTrimGainForQ,
} from "./app/audio/tone-shaping.js";
import { getScreenDefinition } from "./app/config/screens.js";
import { SOURCE_DEFINITIONS, getSourceDefinition } from "./app/config/sources.js";
import { mountScreenControls } from "./app/ui/mount-controls.js";
import { sliderToLogFrequency } from "./app/ui/formatters.js";

const screen = getScreenDefinition();

const controls = {
  ...mountScreenControls(document, screen),
  powerButton: document.querySelector("#powerButton"),
  audioStatus: document.querySelector("#audioStatus"),
  colorTitle: document.querySelector("#colorTitle"),
  colorDescription: document.querySelector("#colorDescription"),
  detailHint: document.querySelector("#detailHint"),
  spectrumCanvas: document.querySelector("#spectrumCanvas"),
  scopeCanvas: document.querySelector("#scopeCanvas"),
};

const appState = createDefaultState();

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function setAudioStatus(text, state) {
  if (!controls.audioStatus) {
    return;
  }

  controls.audioStatus.textContent = text;
  controls.audioStatus.dataset.state = state;
}

function setPowerButtonText(text) {
  if (controls.powerButton) {
    controls.powerButton.textContent = text;
  }
}

function coefficientForCutoff(frequency, sampleRate) {
  return 1 - Math.exp((-2 * Math.PI * frequency) / sampleRate);
}

function createNoiseChannelState() {
  return {
    brown: 0,
    previousPink: 0,
    previousWhite: 0,
    pinkB0: 0,
    pinkB1: 0,
    pinkB2: 0,
    pinkB3: 0,
    pinkB4: 0,
    pinkB5: 0,
    pinkB6: 0,
    air1: 0,
    air2: 0,
    rumble1: 0,
    rumble2: 0,
    humPhase: Math.random() * Math.PI * 2,
    motionPhase: Math.random() * Math.PI * 2,
    flutterPhase: Math.random() * Math.PI * 2,
    drift: 0,
    driftTarget: 0,
    driftCounter: 0,
    phaseOffset: Math.random() * Math.PI * 2,
    coefficientsReady: false,
    airCoeff1: 0,
    airCoeff2: 0,
    rumbleCoeff1: 0,
    rumbleCoeff2: 0,
    sampleRate: 0,
  };
}

function ensureStateCoefficients(state, sampleRate) {
  if (state.coefficientsReady && state.sampleRate === sampleRate) {
    return;
  }

  state.sampleRate = sampleRate;
  state.airCoeff1 = coefficientForCutoff(700, sampleRate);
  state.airCoeff2 = coefficientForCutoff(420, sampleRate);
  state.rumbleCoeff1 = coefficientForCutoff(FAN_RUMBLE_FILTERS.firstCutoff, sampleRate);
  state.rumbleCoeff2 = coefficientForCutoff(FAN_RUMBLE_FILTERS.secondCutoff, sampleRate);
  state.driftCounter = Math.floor(sampleRate * (0.35 + Math.random() * 0.4));
  state.coefficientsReady = true;
}

function generatePinkSample(state, white) {
  state.pinkB0 = 0.99886 * state.pinkB0 + white * 0.0555179;
  state.pinkB1 = 0.99332 * state.pinkB1 + white * 0.0750759;
  state.pinkB2 = 0.969 * state.pinkB2 + white * 0.153852;
  state.pinkB3 = 0.8665 * state.pinkB3 + white * 0.3104856;
  state.pinkB4 = 0.55 * state.pinkB4 + white * 0.5329522;
  state.pinkB5 = -0.7616 * state.pinkB5 - white * 0.016898;

  const pink =
    state.pinkB0 +
    state.pinkB1 +
    state.pinkB2 +
    state.pinkB3 +
    state.pinkB4 +
    state.pinkB5 +
    state.pinkB6 +
    white * 0.5362;

  state.pinkB6 = white * 0.115926;

  return pink * 0.11;
}

function generateBrownSample(state, white) {
  const brown = (state.brown + 0.02 * white) / 1.02;
  state.brown = brown;
  return brown * 3.5;
}

function generateFanSample(state, white, config, sampleRate) {
  ensureStateCoefficients(state, sampleRate);

  const pink = generatePinkSample(state, white);
  const brown = generateBrownSample(state, white);
  const fanAir = config.fanAir ?? DEFAULT_GENERATOR_CONFIG.fanAir;
  const fanRumble = config.fanRumble ?? DEFAULT_GENERATOR_CONFIG.fanRumble;
  const fanHum = config.fanHum ?? DEFAULT_GENERATOR_CONFIG.fanHum;
  const fanHumPitch = config.fanHumPitch ?? DEFAULT_GENERATOR_CONFIG.fanHumPitch;
  const fanDrift = config.fanDrift ?? DEFAULT_GENERATOR_CONFIG.fanDrift;

  const airSource = pink * (1 - FAN_AIR_BROWN_MIX) + brown * FAN_AIR_BROWN_MIX;
  state.air1 += state.airCoeff1 * (airSource - state.air1);
  state.air2 += state.airCoeff2 * (state.air1 - state.air2);
  const air = state.air2;

  const rumbleSource = brown * 0.9 + pink * 0.1;
  state.rumble1 += state.rumbleCoeff1 * (rumbleSource - state.rumble1);
  state.rumble2 += state.rumbleCoeff2 * (state.rumble1 - state.rumble2);
  const rumble = state.rumble2;

  state.driftCounter -= 1;
  if (state.driftCounter <= 0) {
    state.driftCounter = Math.floor(sampleRate * (0.35 + Math.random() * 0.65));
    state.driftTarget = Math.random() * 2 - 1;
  }

  state.drift += 0.00005 * (state.driftTarget - state.drift);
  state.motionPhase += (2 * Math.PI * (0.07 + fanDrift * 0.05)) / sampleRate;
  state.flutterPhase += (2 * Math.PI * (0.17 + fanDrift * 0.11)) / sampleRate;

  if (state.motionPhase > Math.PI * 2) {
    state.motionPhase -= Math.PI * 2;
  }

  if (state.flutterPhase > Math.PI * 2) {
    state.flutterPhase -= Math.PI * 2;
  }

  const motion =
    Math.sin(state.motionPhase + state.phaseOffset) * 0.6 +
    Math.sin(state.flutterPhase * 1.9 + state.phaseOffset * 0.37) * 0.4;
  const humFrequency = fanHumFrequency({
    fanHumPitch,
    fanDrift,
    drift: state.drift,
    motion,
  });

  state.humPhase += (2 * Math.PI * humFrequency) / sampleRate;
  if (state.humPhase > Math.PI * 2) {
    state.humPhase -= Math.PI * 2;
  }

  const humWave =
    Math.sin(state.humPhase) * 0.74 +
    Math.sin(state.humPhase * 2.01 + 0.4) * 0.18 +
    Math.sin(state.humPhase * 3.97 + 1.1) * 0.05;
  const bedMotion = 1 + fanDrift * (state.drift * 0.09 + motion * 0.06);
  const airLevel = fanAirLevel(fanAir);
  const rumbleLevel = fanRumbleLevel(fanRumble);
  const humLevel = fanHumLevel(fanHum);

  return (air * airLevel + rumble * rumbleLevel) * bedMotion + humWave * humLevel;
}

function sampleForMode(mode, state, white, config, sampleRate) {
  switch (mode) {
    case "fan":
      return generateFanSample(state, white, config, sampleRate);
    case "pink":
      return generatePinkSample(state, white) * 0.92;
    case "brown":
      return generateBrownSample(state, white) * 0.85;
    case "blue": {
      const pink = generatePinkSample(state, white);
      const blue = (pink - state.previousPink) * 1.8;
      state.previousPink = pink;
      return blue;
    }
    case "violet": {
      const violet = (white - state.previousWhite) * 0.23;
      state.previousWhite = white;
      return violet;
    }
    case "white":
    default:
      return white * 0.33;
  }
}

function createScriptProcessorNoiseSource(context) {
  const processor = context.createScriptProcessor(4096, 0, 2);
  const channelStates = [createNoiseChannelState(), createNoiseChannelState()];
  let config = { ...DEFAULT_GENERATOR_CONFIG };

  processor.onaudioprocess = (event) => {
    const outputBuffer = event.outputBuffer;

    for (let channelIndex = 0; channelIndex < outputBuffer.numberOfChannels; channelIndex += 1) {
      const channelData = outputBuffer.getChannelData(channelIndex);
      const state = channelStates[channelIndex] ?? createNoiseChannelState();
      channelStates[channelIndex] = state;

      for (let index = 0; index < channelData.length; index += 1) {
        const white = Math.random() * 2 - 1;
        const sample = sampleForMode(config.mode, state, white, config, context.sampleRate);
        channelData[index] = clamp(sample, -1, 1);
      }
    }
  };

  return {
    backend: "script-processor",
    node: processor,
    setConfig(nextConfig) {
      config = {
        ...config,
        ...nextConfig,
      };
    },
  };
}

class NoiseLab {
  constructor() {
    this.context = null;
    this.noiseSource = null;
    this.globalInput = null;
    this.lowCutFilter = null;
    this.highCutFilter = null;
    this.lowShelf = null;
    this.highShelf = null;
    this.greenBandpass = null;
    this.greenTrim = null;
    this.greyLowShelf = null;
    this.greyDip = null;
    this.greyHighShelf = null;
    this.greyTrim = null;
    this.widthInput = null;
    this.masterGain = null;
    this.spectrumAnalyser = null;
    this.scopeAnalyser = null;
    this.widthNodes = null;
    this.routingMode = "";
    this.visualizerFrame = 0;
    this.spectrumData = null;
    this.scopeData = null;
    this.isInitialized = false;
    this.initializePromise = null;
  }

  resetAudioState() {
    cancelAnimationFrame(this.visualizerFrame);
    this.visualizerFrame = 0;
    this.context = null;
    this.noiseSource = null;
    this.globalInput = null;
    this.lowCutFilter = null;
    this.highCutFilter = null;
    this.lowShelf = null;
    this.highShelf = null;
    this.greenBandpass = null;
    this.greenTrim = null;
    this.greyLowShelf = null;
    this.greyDip = null;
    this.greyHighShelf = null;
    this.greyTrim = null;
    this.widthInput = null;
    this.masterGain = null;
    this.spectrumAnalyser = null;
    this.scopeAnalyser = null;
    this.widthNodes = null;
    this.routingMode = "";
    this.spectrumData = null;
    this.scopeData = null;
    this.isInitialized = false;
  }

  createAudioContext(AudioContextClass) {
    try {
      return new AudioContextClass({ latencyHint: "interactive" });
    } catch {
      return new AudioContextClass();
    }
  }

  getGeneratorConfig() {
    const source = getSourceDefinition(appState.noiseType);

    return {
      mode: source.generatorMode,
      fanAir: appState.fanAir / 100,
      fanRumble: appState.fanRumble / 100,
      fanHum: appState.fanHum / 100,
      fanHumPitch: appState.fanHumPitch,
      fanDrift: appState.fanDrift / 100,
    };
  }

  async createNoiseSource(context) {
    if (
      context.audioWorklet &&
      typeof context.audioWorklet.addModule === "function" &&
      typeof AudioWorkletNode === "function"
    ) {
      try {
        await context.audioWorklet.addModule("/noise-generator.worklet.js");

        const node = new AudioWorkletNode(context, "colored-noise-processor", {
          numberOfOutputs: 1,
          outputChannelCount: [2],
        });

        return {
          backend: "audio-worklet",
          node,
          setConfig(nextConfig) {
            node.port.postMessage({ type: "config", value: nextConfig });
          },
        };
      } catch (error) {
        console.warn("AudioWorklet initialization failed. Falling back to ScriptProcessorNode.", error);
      }
    }

    if (typeof context.createScriptProcessor !== "function") {
      throw new Error("This browser does not support a compatible live audio generator.");
    }

    return createScriptProcessorNoiseSource(context);
  }

  async ensureInitialized() {
    if (this.isInitialized) {
      return;
    }

    if (!this.initializePromise) {
      this.initializePromise = this.initialize().finally(() => {
        this.initializePromise = null;
      });
    }

    await this.initializePromise;
  }

  async start() {
    await this.ensureInitialized();

    if (!this.context || !this.noiseSource || !this.masterGain || !this.spectrumAnalyser || !this.scopeAnalyser) {
      throw new Error("Audio initialization failed.");
    }

    await this.context.resume();
    setAudioStatus("Running", "running");
    setPowerButtonText("Pause Audio");
    this.startVisualizers();
    this.applyState();
  }

  async stop() {
    cancelAnimationFrame(this.visualizerFrame);

    if (!this.context || this.context.state === "closed") {
      return;
    }

    await this.context.suspend();
    setAudioStatus("Paused", "paused");
    setPowerButtonText("Resume Audio");
  }

  async initialize() {
    if (this.isInitialized) {
      return;
    }

    const AudioContextClass = window.AudioContext || window.webkitAudioContext;

    if (!AudioContextClass) {
      throw new Error("This browser does not support the Web Audio API.");
    }

    let context = null;

    try {
      context = this.createAudioContext(AudioContextClass);
      const noiseSource = await this.createNoiseSource(context);

      this.context = context;
      this.noiseSource = noiseSource;

      this.globalInput = this.context.createGain();
      this.lowCutFilter = this.context.createBiquadFilter();
      this.lowCutFilter.type = "highpass";
      this.lowCutFilter.Q.value = 0.707;

      this.highCutFilter = this.context.createBiquadFilter();
      this.highCutFilter.type = "lowpass";
      this.highCutFilter.Q.value = 0.707;

      this.lowShelf = this.context.createBiquadFilter();
      this.lowShelf.type = "lowshelf";
      this.lowShelf.frequency.value = 250;

      this.highShelf = this.context.createBiquadFilter();
      this.highShelf.type = "highshelf";
      this.highShelf.frequency.value = 4000;

      this.greenBandpass = this.context.createBiquadFilter();
      this.greenBandpass.type = "bandpass";
      this.greenTrim = this.context.createGain();

      this.greyLowShelf = this.context.createBiquadFilter();
      this.greyLowShelf.type = "lowshelf";
      this.greyLowShelf.frequency.value = 180;

      this.greyDip = this.context.createBiquadFilter();
      this.greyDip.type = "peaking";
      this.greyDip.frequency.value = 3500;
      this.greyDip.Q.value = 0.85;

      this.greyHighShelf = this.context.createBiquadFilter();
      this.greyHighShelf.type = "highshelf";
      this.greyHighShelf.frequency.value = 7000;

      this.greyTrim = this.context.createGain();
      this.widthInput = this.context.createGain();
      this.masterGain = this.context.createGain();

      this.spectrumAnalyser = this.context.createAnalyser();
      this.spectrumAnalyser.fftSize = 4096;
      this.spectrumAnalyser.smoothingTimeConstant = 0.82;

      this.scopeAnalyser = this.context.createAnalyser();
      this.scopeAnalyser.fftSize = 2048;
      this.scopeAnalyser.smoothingTimeConstant = 0.2;

      this.spectrumData = new Uint8Array(this.spectrumAnalyser.frequencyBinCount);
      this.scopeData = new Uint8Array(this.scopeAnalyser.fftSize);

      this.globalInput.connect(this.lowCutFilter);
      this.lowCutFilter.connect(this.highCutFilter);
      this.highCutFilter.connect(this.lowShelf);
      this.lowShelf.connect(this.highShelf);
      this.highShelf.connect(this.widthInput);

      this.buildWidthMatrix();

      this.masterGain.connect(this.context.destination);
      this.masterGain.connect(this.spectrumAnalyser);
      this.masterGain.connect(this.scopeAnalyser);

      this.isInitialized = true;
      this.applyState();
    } catch (error) {
      if (context && typeof context.close === "function" && context.state !== "closed") {
        try {
          await context.close();
        } catch {
          // Ignore close errors and surface the original initialization failure.
        }
      }

      this.resetAudioState();
      throw error;
    }
  }

  buildWidthMatrix() {
    const splitter = this.context.createChannelSplitter(2);
    const merger = this.context.createChannelMerger(2);

    this.widthInput.connect(splitter);

    this.widthNodes = {
      leftToLeft: this.context.createGain(),
      rightToLeft: this.context.createGain(),
      leftToRight: this.context.createGain(),
      rightToRight: this.context.createGain(),
      merger,
      splitter,
    };

    splitter.connect(this.widthNodes.leftToLeft, 0);
    splitter.connect(this.widthNodes.leftToRight, 0);
    splitter.connect(this.widthNodes.rightToLeft, 1);
    splitter.connect(this.widthNodes.rightToRight, 1);

    this.widthNodes.leftToLeft.connect(merger, 0, 0);
    this.widthNodes.rightToLeft.connect(merger, 0, 0);
    this.widthNodes.leftToRight.connect(merger, 0, 1);
    this.widthNodes.rightToRight.connect(merger, 0, 1);

    merger.connect(this.masterGain);
  }

  reconnectColorChain() {
    const disconnectSafely = (node) => {
      if (!node) {
        return;
      }

      try {
        node.disconnect();
      } catch {
        return;
      }
    };

    const sourceNode = this.noiseSource?.node;

    if (!sourceNode || !this.globalInput) {
      return;
    }

    disconnectSafely(sourceNode);
    disconnectSafely(this.greenBandpass);
    disconnectSafely(this.greenTrim);
    disconnectSafely(this.greyLowShelf);
    disconnectSafely(this.greyDip);
    disconnectSafely(this.greyHighShelf);
    disconnectSafely(this.greyTrim);

    const route = getSourceDefinition(appState.noiseType).route;

    if (route === "green") {
      sourceNode.connect(this.greenBandpass);
      this.greenBandpass.connect(this.greenTrim);
      this.greenTrim.connect(this.globalInput);
      this.routingMode = route;
      return;
    }

    if (route === "grey") {
      sourceNode.connect(this.greyLowShelf);
      this.greyLowShelf.connect(this.greyDip);
      this.greyDip.connect(this.greyHighShelf);
      this.greyHighShelf.connect(this.greyTrim);
      this.greyTrim.connect(this.globalInput);
      this.routingMode = route;
      return;
    }

    sourceNode.connect(this.globalInput);
    this.routingMode = route;
  }

  setWidth(widthPercent) {
    if (!this.widthNodes || !this.context) {
      return;
    }

    const width = clamp(widthPercent / 100, 0, 2);
    const sameSide = (1 + width) * 0.5;
    const crossSide = (1 - width) * 0.5;

    this.widthNodes.leftToLeft.gain.setTargetAtTime(sameSide, this.context.currentTime, 0.02);
    this.widthNodes.rightToRight.gain.setTargetAtTime(sameSide, this.context.currentTime, 0.02);
    this.widthNodes.leftToRight.gain.setTargetAtTime(crossSide, this.context.currentTime, 0.02);
    this.widthNodes.rightToLeft.gain.setTargetAtTime(crossSide, this.context.currentTime, 0.02);
  }

  applyState() {
    updateLabels();
    updateText();

    if (!this.context || !this.noiseSource || !this.masterGain) {
      return;
    }

    const currentTime = this.context.currentTime;
    this.noiseSource.setConfig(this.getGeneratorConfig());

    const source = getSourceDefinition(appState.noiseType);

    if (this.routingMode !== source.route) {
      this.reconnectColorChain();
    }

    const level = clamp(appState.level / 100, 0, 1);
    const gain = level ** 2 * 0.9;
    this.masterGain.gain.setTargetAtTime(gain, currentTime, 0.03);

    this.lowCutFilter.frequency.setTargetAtTime(
      sliderToLogFrequency(appState.lowCut, 20, 1500),
      currentTime,
      0.03,
    );
    this.highCutFilter.frequency.setTargetAtTime(
      sliderToLogFrequency(appState.highCut, 1200, 20000),
      currentTime,
      0.03,
    );

    this.lowShelf.gain.setTargetAtTime(-appState.tilt, currentTime, 0.03);
    this.highShelf.gain.setTargetAtTime(appState.tilt, currentTime, 0.03);
    this.setWidth(appState.width);

    const greenCenter = sliderToLogFrequency(appState.greenCenter, 180, 4200);
    const greenQ = clamp(appState.greenQ / 100, 0.3, 6);
    this.greenBandpass.frequency.setTargetAtTime(greenCenter, currentTime, 0.03);
    this.greenBandpass.Q.setTargetAtTime(greenQ, currentTime, 0.03);
    this.greenTrim.gain.setTargetAtTime(greenTrimGainForQ(greenQ), currentTime, 0.03);

    const greyAmount = clamp(appState.greyAmount / 100, 0, 1.5);
    this.greyLowShelf.gain.setTargetAtTime(12 * greyAmount, currentTime, 0.03);
    this.greyDip.gain.setTargetAtTime(-11 * greyAmount, currentTime, 0.03);
    this.greyHighShelf.gain.setTargetAtTime(5 * greyAmount, currentTime, 0.03);
    this.greyTrim.gain.setTargetAtTime(0.38, currentTime, 0.03);
  }

  startVisualizers() {
    if (!this.spectrumAnalyser || !this.scopeAnalyser || !this.spectrumData || !this.scopeData || !this.context) {
      return;
    }

    const spectrumCanvas = controls.spectrumCanvas;
    const scopeCanvas = controls.scopeCanvas;

    if (!spectrumCanvas || !scopeCanvas) {
      return;
    }
    const spectrumContext = spectrumCanvas.getContext("2d");
    const scopeContext = scopeCanvas.getContext("2d");

    if (!spectrumContext || !scopeContext) {
      return;
    }

    const draw = () => {
      this.visualizerFrame = requestAnimationFrame(draw);

      if (this.context?.state !== "running") {
        return;
      }

      this.spectrumAnalyser.getByteFrequencyData(this.spectrumData);
      this.scopeAnalyser.getByteTimeDomainData(this.scopeData);

      drawSpectrum(spectrumContext, spectrumCanvas, this.spectrumData, this.context.sampleRate);
      drawScope(scopeContext, scopeCanvas, this.scopeData);
    };

    cancelAnimationFrame(this.visualizerFrame);
    draw();
  }
}

function drawSpectrum(context, canvas, spectrumData, sampleRate) {
  const width = canvas.width;
  const height = canvas.height;
  const gradient = context.createLinearGradient(0, 0, 0, height);
  gradient.addColorStop(0, "rgba(242, 198, 109, 0.9)");
  gradient.addColorStop(1, "rgba(87, 199, 215, 0.18)");

  context.clearRect(0, 0, width, height);
  context.fillStyle = "rgba(6, 12, 18, 0.82)";
  context.fillRect(0, 0, width, height);

  context.strokeStyle = "rgba(255, 255, 255, 0.08)";
  context.lineWidth = 1;
  const guideFrequencies = [20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000];

  for (const frequency of guideFrequencies) {
    const ratio = Math.log10(frequency / 20) / Math.log10(20000 / 20);
    const x = ratio * width;
    context.beginPath();
    context.moveTo(x, 0);
    context.lineTo(x, height);
    context.stroke();
  }

  context.fillStyle = gradient;
  context.beginPath();
  context.moveTo(0, height);

  for (let x = 0; x < width; x += 1) {
    const logRatio = x / width;
    const frequency = 20 * (20000 / 20) ** logRatio;
    const index = clamp(
      Math.round((frequency / (sampleRate / 2)) * (spectrumData.length - 1)),
      0,
      spectrumData.length - 1,
    );
    const magnitude = spectrumData[index] / 255;
    const y = height - magnitude * (height - 18);
    context.lineTo(x, y);
  }

  context.lineTo(width, height);
  context.closePath();
  context.fill();

  context.fillStyle = "rgba(236, 246, 255, 0.7)";
  context.font = '12px "Avenir Next", "Segoe UI", sans-serif';

  for (const frequency of guideFrequencies) {
    const ratio = Math.log10(frequency / 20) / Math.log10(20000 / 20);
    const x = ratio * width;
    const label = frequency >= 1000 ? `${frequency / 1000}k` : `${frequency}`;
    context.fillText(label, Math.min(width - 22, x + 4), height - 8);
  }
}

function drawScope(context, canvas, scopeData) {
  const width = canvas.width;
  const height = canvas.height;
  context.clearRect(0, 0, width, height);
  context.fillStyle = "rgba(6, 12, 18, 0.82)";
  context.fillRect(0, 0, width, height);

  context.strokeStyle = "rgba(255, 255, 255, 0.08)";
  context.lineWidth = 1;
  context.beginPath();
  context.moveTo(0, height / 2);
  context.lineTo(width, height / 2);
  context.stroke();

  context.strokeStyle = "rgba(140, 224, 200, 0.92)";
  context.lineWidth = 2;
  context.beginPath();

  for (let index = 0; index < scopeData.length; index += 1) {
    const x = (index / (scopeData.length - 1)) * width;
    const y = (scopeData[index] / 255) * height;

    if (index === 0) {
      context.moveTo(x, y);
    } else {
      context.lineTo(x, y);
    }
  }

  context.stroke();
}

function updateLabels() {
  for (const control of CONTROL_DEFINITIONS) {
    if (!control.formatValue) {
      continue;
    }

    const output = controls[`${control.id}Value`];

    if (output) {
      output.textContent = control.formatValue(appState[control.id]);
    }
  }
}

function updateText() {
  const source = getSourceDefinition(appState.noiseType);

  if (controls.colorTitle) {
    controls.colorTitle.textContent = source.title;
  }

  if (controls.colorDescription) {
    controls.colorDescription.textContent = source.description;
  }

  if (controls.detailHint) {
    controls.detailHint.textContent = source.detail;
  }

  for (const sourceDefinition of SOURCE_DEFINITIONS) {
    const group = controls[`${sourceDefinition.id}Controls`];

    if (group) {
      group.hidden = sourceDefinition.id !== source.id;
    }
  }
}

const lab = new NoiseLab();

if (controls.powerButton) {
  controls.powerButton.addEventListener("click", async () => {
    try {
      if (lab.context?.state === "running") {
        await lab.stop();
      } else {
        await lab.start();
      }
    } catch (error) {
      setAudioStatus(error instanceof Error ? error.message : "Unable to start audio", "error");
      setPowerButtonText("Start Audio");
    }
  });
}

for (const control of CONTROL_DEFINITIONS) {
  const input = controls[control.id];

  if (!input) {
    continue;
  }

  input.addEventListener("input", (event) => {
    appState[control.id] = parseControlValue(control, event.currentTarget.value);
    lab.applyState();
  });
}

setAudioStatus("Idle", "idle");
updateLabels();
updateText();
