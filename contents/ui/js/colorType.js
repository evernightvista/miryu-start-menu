.pragma library

function isDark(color) {

  const r = color.r;
  const g = color.g;
  const b = color.b;

  // Using the HSP value, determine whether the color is light or dark
  const colorArray = [r, g , b ].map(v => {
    if (v <= 0.03928) {
      return v / 12.92
    }

    return Math.pow((v + 0.055) / 1.055, 2.4)
  })

  const luminance = 0.2126 * colorArray[0] + 0.7152 * colorArray[1] + 0.0722 * colorArray[2]

  return luminance <= 0.179
}