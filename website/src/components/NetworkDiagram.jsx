export default function NetworkDiagram() {
  return (
    <figure className="network">
      <div className="network__legend" aria-hidden="true">
        <span><i className="legend-line" /> Same network</span>
        <span><i className="legend-line legend-line--dash" /> Direct WebRTC</span>
        <span><i className="legend-line legend-line--dot" /> Relay fallback</span>
      </div>

      <div className="network__grid">
        <div className="network__node network__node--a">
          <b>Device A</b>
          <span>Relay</span>
        </div>

        <div className="network__route network__route--r1">
          <span><b>1 · Same network</b><br />direct, no server in the path</span>
        </div>
        <div className="network__route network__route--r2">
          <span><b>2 · Different networks</b><br />direct WebRTC when NAT allows</span>
        </div>
        <div className="network__route network__route--r3">
          <span><b>3 · Restrictive networks</b><br />encrypted relay, only as fallback</span>
        </div>

        <div className="network__node network__node--b">
          <b>Device B</b>
          <span>Relay</span>
        </div>
      </div>

      <figcaption className="network__caption">
        A small WebSocket signaling room introduces the two devices. It carries
        session metadata, not file bytes. When a direct path fails, TURN relays
        encrypted WebRTC packets. Documents are never uploaded to a cloud
        library.
      </figcaption>
    </figure>
  );
}
