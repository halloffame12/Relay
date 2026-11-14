const SIZE = 21;

function inFinder(x, y) {
  return (
    (x <= 7 && y <= 7) || (x >= SIZE - 8 && y <= 7) || (x <= 7 && y >= SIZE - 8)
  );
}

function finderOrigin(x, y) {
  if (x <= 7 && y <= 7) return [0, 0];
  if (x >= SIZE - 8 && y <= 7) return [SIZE - 7, 0];
  if (x <= 7 && y >= SIZE - 8) return [0, SIZE - 7];
  return null;
}

function dataModule(x, y) {
  if (inFinder(x, y)) return false;
  if (y === 6 && x > 7 && x < SIZE - 8) return x % 2 === 0;
  if (x === 6 && y > 7 && y < SIZE - 8) return y % 2 === 0;
  return (x * 7 + y * 11 + ((x * y) % 5)) % 9 < 4;
}

/**
 * A decorative QR-shaped mark. It is deliberately not a scannable code and is
 * always labelled as illustrative in the surrounding UI.
 */
export default function QrMark() {
  const modules = [];
  for (let y = 0; y < SIZE; y += 1) {
    for (let x = 0; x < SIZE; x += 1) {
      if (dataModule(x, y)) modules.push(`${x}-${y}`);
    }
  }

  const finders = [];
  for (let y = 0; y < SIZE; y += 1) {
    for (let x = 0; x < SIZE; x += 1) {
      const origin = finderOrigin(x, y);
      if (!origin) continue;
      const [ox, oy] = origin;
      const dx = x - ox;
      const dy = y - oy;
      const outer = dx === 0 || dy === 0 || dx === 6 || dy === 6;
      const center = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
      if (outer || center) finders.push(`${x}-${y}`);
    }
  }

  return (
    <svg
      viewBox={`0 0 ${SIZE} ${SIZE}`}
      shapeRendering="crispEdges"
      aria-label="Illustrative QR code"
      role="img"
      focusable="false"
    >
      <rect width={SIZE} height={SIZE} fill="#ffffff" />
      <g fill="#0e0e10">
        {modules.map((key) => {
          const [x, y] = key.split("-").map(Number);
          return <rect key={key} x={x} y={y} width="1" height="1" />;
        })}
        {finders.map((key) => {
          const [x, y] = key.split("-").map(Number);
          return <rect key={key} x={x} y={y} width="1" height="1" />;
        })}
        <rect x="7" y="7" width="1" height="1" />
        <rect x="13" y="7" width="1" height="1" />
        <rect x="7" y="13" width="1" height="1" />
        <rect x="13" y="13" width="1" height="1" />
      </g>
    </svg>
  );
}
