let current_panel = 'player';
const base_layer = 'player'
const overlay_layers = ['library', 'settings', 'notification'];

window.onload = function () {
  console.log("Page loaded");
}

function sleep(s) {
  return new Promise(resolve => setTimeout(resolve, 1000*s));
}

function switchLayer(layer) {
  console.log(`Focussing ${layer}`);

  // If layer is PLAYER, hide all overlays
  if (layer === base_layer) {
    document.body.classList.remove('overlay-open');
    overlay_layers.forEach(n => {
      console.log(`Deactivating ${n.toLowerCase()}-layer`);
      const l = document.getElementById(`${n.toLowerCase()}-layer`);
      l.classList.remove('active-layer');
    });

  // Else hide all other layers and make this one active
  } else {
    document.body.classList.add('overlay-open');
    overlay_layers.forEach(n => {
      const l = document.getElementById(`${n.toLowerCase()}-layer`);
      if (layer === n) {
        console.log(`Activating ${n.toLowerCase()}-layer`);
        l.classList.add('active-layer');
      } else {
        console.log(`Deactivating ${n.toLowerCase()}-layer`);
        l.classList.remove('active-layer');
      }
    });

    current_layer = layer;
  }
}

