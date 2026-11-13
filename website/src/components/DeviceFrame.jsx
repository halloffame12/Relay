import Image from "next/image";

export default function DeviceFrame({
  src,
  alt,
  width = 300,
  height = 650,
  caption,
  badge,
  className = "",
  priority = false,
}) {
  return (
    <figure className={`device-figure ${className}`}>
      <div className="device-outer">
        <div className="device-speaker"></div>
        <div className="device-screen">
          <Image
            src={src}
            alt={alt}
            width={width}
            height={height}
            className="device-img"
            priority={priority}
          />
        </div>
        {badge && <span className="device-badge">{badge}</span>}
      </div>
      {caption && (
        <figcaption className="device-caption">
          <span className="caption-dot"></span>
          <span>{caption}</span>
        </figcaption>
      )}
    </figure>
  );
}

