import React from "react";

const LazyComponent = () => (
  <div>
    <h2>I am a lazily loaded component!</h2>
    <p>My module is fetched only when React.lazy resolves it.</p>
  </div>
);

export default LazyComponent;
