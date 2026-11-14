export default function Phone({ children, caption, device, className = "" }) {
  return (
    <div className={`device ${className}`}>
      <div className="phone">
        <div className="phone__screen">{children}</div>
      </div>
      {caption && (
        <p className="device__caption">
          {device && <b>{device}</b>}
          <span>{caption}</span>
        </p>
      )}
    </div>
  );
}
