export function sliderToLogFrequency(value, min, max) {
  const ratio = value / 100;
  return min * (max / min) ** ratio;
}

export function formatFrequency(value) {
  if (value >= 1000) {
    return `${(value / 1000).toFixed(value >= 10000 ? 1 : 2).replace(/\.0$/, "")} kHz`;
  }

  return `${Math.round(value)} Hz`;
}

export function formatPercent(value) {
  return `${value}%`;
}

export function formatSignedDecibels(value) {
  return `${value > 0 ? "+" : ""}${value} dB`;
}

export function formatLowCut(value) {
  return formatFrequency(sliderToLogFrequency(value, 20, 1500));
}

export function formatHighCut(value) {
  return formatFrequency(sliderToLogFrequency(value, 1200, 20000));
}

export function formatGreenCenter(value) {
  return formatFrequency(sliderToLogFrequency(value, 180, 4200));
}

export function formatQ(value) {
  return (value / 100).toFixed(1);
}
