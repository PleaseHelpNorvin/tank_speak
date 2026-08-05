let bluetoothDevice = null;
let gattServer = null;

window.requestBluetoothDevice = async function () {

    if (!navigator.bluetooth) {
        throw new Error("Web Bluetooth is not supported.");
    }

    bluetoothDevice = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: []
    });

    return bluetoothDevice.name;
};

window.connectBluetooth = async function () {

    if (!bluetoothDevice)
        throw new Error("No device selected.");

    gattServer = await bluetoothDevice.gatt.connect();

    return true;
};

window.disconnectBluetooth = function () {

    if (bluetoothDevice?.gatt?.connected) {
        bluetoothDevice.gatt.disconnect();
    }

    return true;
};

window.isConnected = function () {

    return bluetoothDevice?.gatt?.connected ?? false;

};