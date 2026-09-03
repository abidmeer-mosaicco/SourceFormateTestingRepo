export function generateOrderNumber() {
    const randomNum = Math.floor(Math.random() * 900000) + 100000;
    return `${randomNum}`;
}

export function getRandomQuantity() {
    const qty = Math.floor(Math.random() * 50) + 1;
    return `${qty}`;
}

export function getRandomShipMethod() {
    const methods = ['Customer Truck', 'Rail', 'Ship', 'Air Freight', 'Intermodal'];
    return methods[Math.floor(Math.random() * methods.length)];
}

export function getRandomOrigin() {
    const origins = ['New Waves, FL', 'Houston, TX', 'Los Angeles, CA', 'New York, NY', 'Atlanta, GA'];
    return origins[Math.floor(Math.random() * origins.length)];
}

export function getRandomDestination() {
    const destinations = [
        'FLORIDA CHEMICAL - JACKSONVILLE, FL\n9469 EASTPORT ROAD, 32218',
        'Seattle, WA', 'Denver, CO', 'Phoenix, AZ', 'Detroit, MI'
    ];
    return destinations[Math.floor(Math.random() * destinations.length)];
}

export function getRandomFutureDate() {
    const today = new Date();
    const futureDate = new Date(today);
    const daysToAdd = Math.floor(Math.random() * 30) + 1;
    futureDate.setDate(today.getDate() + daysToAdd);
    return futureDate;
}

export function generateSampleOrderItems(orderId) {
    const sampleItems = [
        {
            id: `${orderId}-item-1`,
            contractItem: '20',
            reqShipmentDate: formatDate(this.getRandomFutureDate()),
            orderNumber: generateOrderNumber(),
            orderQty: getRandomQuantity(),
            uom: 'MTN',
            shipMethod: getRandomShipMethod(),
            origin: getRandomOrigin(),
            shipTo: getRandomDestination()
        },
        {
            id: `${orderId}-item-2`,
            contractItem: '20',
            reqShipmentDate: formatDate(this.getRandomFutureDate()),
            orderNumber: generateOrderNumber(),
            orderQty: getRandomQuantity(),
            uom: 'MTN',
            shipMethod: getRandomShipMethod(),
            origin: getRandomOrigin(),
            shipTo: getRandomDestination()
        },
        {
            id: `${orderId}-item-3`,
            contractItem: '20',
            reqShipmentDate: formatDate(this.getRandomFutureDate()),
            orderNumber: generateOrderNumber(),
            orderQty: getRandomQuantity(),
            uom: 'MTN',
            shipMethod: getRandomShipMethod(),
            origin: getRandomOrigin(),
            shipTo: getRandomDestination()
        }
    ];

    const itemCount = Math.floor(Math.random() * 3) + 1;
    return sampleItems.slice(0, itemCount);
}

export function formatDate(date) {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const year = String(date.getFullYear()).slice(-2);
    return `${month}/${day}/${year}`;
}