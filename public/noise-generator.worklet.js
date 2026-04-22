class ColoredNoiseProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.config = {
      mode: "white",
      fanAir: 0.55,
      fanRumble: 0.65,
      fanHum: 0.52,
      fanDrift: 0.32,
    };
    this.channelStates = [];

    this.port.onmessage = (event) => {
      if (event.data?.type === "mode") {
        this.config.mode = event.data.value;
        return;
      }

      if (event.data?.type === "config" && event.data.value) {
        this.config = {
          ...this.config,
          ...event.data.value,
        };
      }
    };
  }

  coefficientForCutoff(frequency) {
    return 1 - Math.exp((-2 * Math.PI * frequency) / sampleRate);
  }

  ensureState(channelIndex) {
    if (!this.channelStates[channelIndex]) {
      this.channelStates[channelIndex] = {
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
        driftCounter: Math.floor(sampleRate * (0.35 + Math.random() * 0.4)),
        phaseOffset: Math.random() * Math.PI * 2,
        airCoeff1: this.coefficientForCutoff(700),
        airCoeff2: this.coefficientForCutoff(420),
        rumbleCoeff1: this.coefficientForCutoff(70),
        rumbleCoeff2: this.coefficientForCutoff(32),
      };
    }

    return this.channelStates[channelIndex];
  }

  generatePink(state, white) {
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

  generateBrown(state, white) {
    const brown = (state.brown + 0.02 * white) / 1.02;
    state.brown = brown;
    return brown * 3.5;
  }

  generateFan(state, white) {
    const pink = this.generatePink(state, white);
    const brown = this.generateBrown(state, white);
    const fanAir = this.config.fanAir ?? 0.55;
    const fanRumble = this.config.fanRumble ?? 0.65;
    const fanHum = this.config.fanHum ?? 0.52;
    const fanDrift = this.config.fanDrift ?? 0.32;

    const airSource = pink * 0.82 + brown * 0.18;
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
    const humFrequency = 92 + (state.drift * 4.5 + motion * 2.2) * fanDrift;

    state.humPhase += (2 * Math.PI * humFrequency) / sampleRate;
    if (state.humPhase > Math.PI * 2) {
      state.humPhase -= Math.PI * 2;
    }

    const humWave =
      Math.sin(state.humPhase) * 0.74 +
      Math.sin(state.humPhase * 2.01 + 0.4) * 0.18 +
      Math.sin(state.humPhase * 3.97 + 1.1) * 0.05;
    const bedMotion = 1 + fanDrift * (state.drift * 0.09 + motion * 0.06);
    const airLevel = 0.12 + fanAir * 0.22;
    const rumbleLevel = 0.18 + fanRumble * 0.55;
    const humLevel = 0.04 + fanHum * 0.16;

    return (air * airLevel + rumble * rumbleLevel) * bedMotion + humWave * humLevel;
  }

  sampleForMode(mode, state, white) {
    switch (mode) {
      case "fan":
        return this.generateFan(state, white);
      case "pink":
        return this.generatePink(state, white) * 0.92;
      case "brown":
        return this.generateBrown(state, white) * 0.85;
      case "blue": {
        const pink = this.generatePink(state, white);
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

  process(_inputs, outputs) {
    const output = outputs[0];

    for (let channelIndex = 0; channelIndex < output.length; channelIndex += 1) {
      const channel = output[channelIndex];
      const state = this.ensureState(channelIndex);

      for (let index = 0; index < channel.length; index += 1) {
        const white = Math.random() * 2 - 1;
        const sample = this.sampleForMode(this.config.mode, state, white);
        channel[index] = Math.max(-1, Math.min(1, sample));
      }
    }

    return true;
  }
}

registerProcessor("colored-noise-processor", ColoredNoiseProcessor);
