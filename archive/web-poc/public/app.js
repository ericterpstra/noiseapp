import {
  CONTROL_DEFINITIONS,
  createDefaultState,
  parseControlValue,
} from "./app/config/controls.js";
import {
  DEFAULT_SLEEP_TONE_CONFIG,
  createSleepToneChannelState,
  generateSleepToneSample,
} from "./app/audio/sleep-tone-dsp.js";
import { getScreenDefinition } from "./app/config/screens.js";
import { mountScreenControls } from "./app/ui/mount-controls.js";
import { sliderToLogFrequency } from "./app/ui/formatters.js";

const screen = getScreenDefinition();

const controls = {
  ...mountScreenControls(document, screen),
  powerButton: document.querySelector("#powerButton"),
  audioStatus: document.querySelector("#audioStatus"),
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

function createScriptProcessorNoiseSource(context) {
  const processor = context.createScriptProcessor(4096, 0, 2);
  const channelStates = [
    createSleepToneChannelState(context.sampleRate),
    createSleepToneChannelState(context.sampleRate),
  ];
  let config = { ...DEFAULT_SLEEP_TONE_CONFIG };

  processor.onaudioprocess = (event) => {
    const outputBuffer = event.outputBuffer;

    for (let channelIndex = 0; channelIndex < outputBuffer.numberOfChannels; channelIndex += 1) {
      const channelData = outputBuffer.getChannelData(channelIndex);
      const state = channelStates[channelIndex] ?? createSleepToneChannelState(context.sampleRate);
      channelStates[channelIndex] = state;

      for (let index = 0; index < channelData.length; index += 1) {
        const white = Math.random() * 2 - 1;
        const sample = generateSleepToneSample(state, white, config, context.sampleRate);
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
    this.widthInput = null;
    this.masterGain = null;
    this.widthNodes = null;
    this.isInitialized = false;
    this.initializePromise = null;
  }

  resetAudioState() {
    this.context = null;
    this.noiseSource = null;
    this.globalInput = null;
    this.lowCutFilter = null;
    this.highCutFilter = null;
    this.lowShelf = null;
    this.highShelf = null;
    this.widthInput = null;
    this.masterGain = null;
    this.widthNodes = null;
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
    return {
      fanAir: appState.fanAir / 100,
      fanRumble: appState.fanRumble / 100,
      fanHum: appState.fanHum / 100,
      fanHumPitch: appState.fanHumPitch,
      fanDrift: appState.fanDrift / 100,
      greenMix: appState.greenMix / 100,
      warmth: appState.warmth / 100,
      lowCut: appState.lowCut / 100,
      highCut: appState.highCut / 100,
      width: appState.width / 100,
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

        const node = new AudioWorkletNode(context, "sleep-tone-processor", {
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

    if (!this.context || !this.noiseSource || !this.masterGain) {
      throw new Error("Audio initialization failed.");
    }

    await this.context.resume();
    setAudioStatus("Running", "running");
    setPowerButtonText("Pause Audio");
    this.applyState();
  }

  async stop() {
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
      this.lowShelf.frequency.value = 220;

      this.highShelf = this.context.createBiquadFilter();
      this.highShelf.type = "highshelf";
      this.highShelf.frequency.value = 2600;

      this.widthInput = this.context.createGain();
      this.masterGain = this.context.createGain();
      this.masterGain.gain.value = 0;

      this.noiseSource.node.connect(this.globalInput);
      this.globalInput.connect(this.lowCutFilter);
      this.lowCutFilter.connect(this.highCutFilter);
      this.highCutFilter.connect(this.lowShelf);
      this.lowShelf.connect(this.highShelf);
      this.highShelf.connect(this.widthInput);

      this.buildWidthMatrix();
      this.masterGain.connect(this.context.destination);

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

    if (!this.context || !this.noiseSource || !this.masterGain) {
      return;
    }

    const currentTime = this.context.currentTime;
    this.noiseSource.setConfig(this.getGeneratorConfig());

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

    const warmth = clamp(appState.warmth / 100, 0, 1);
    this.lowShelf.gain.setTargetAtTime(warmth * 5, currentTime, 0.03);
    this.highShelf.gain.setTargetAtTime(warmth * -8, currentTime, 0.03);
    this.setWidth(appState.width);
  }
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
