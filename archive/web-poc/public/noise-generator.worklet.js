import {
  DEFAULT_SLEEP_TONE_CONFIG,
  createSleepToneChannelState,
  generateSleepToneSample,
} from "./app/audio/sleep-tone-dsp.js";

class SleepToneProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.config = { ...DEFAULT_SLEEP_TONE_CONFIG };
    this.channelStates = [];

    this.port.onmessage = (event) => {
      if (event.data?.type === "config" && event.data.value) {
        this.config = {
          ...this.config,
          ...event.data.value,
        };
      }
    };
  }

  ensureState(channelIndex) {
    if (!this.channelStates[channelIndex]) {
      this.channelStates[channelIndex] = createSleepToneChannelState(sampleRate);
    }

    return this.channelStates[channelIndex];
  }

  process(_inputs, outputs) {
    const output = outputs[0];

    for (let channelIndex = 0; channelIndex < output.length; channelIndex += 1) {
      const channel = output[channelIndex];
      const state = this.ensureState(channelIndex);

      for (let index = 0; index < channel.length; index += 1) {
        const white = Math.random() * 2 - 1;
        const sample = generateSleepToneSample(state, white, this.config, sampleRate);
        channel[index] = Math.max(-1, Math.min(1, sample));
      }
    }

    return true;
  }
}

registerProcessor("sleep-tone-processor", SleepToneProcessor);
