import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderCart from '@salesforce/apex/MosaicDirectOrderTableCtrl.getOrderCart';
import updateOrderCartItem from '@salesforce/apex/OrderCartService.updateOrderCartItem';
import deleteOrderCartItem from '@salesforce/apex/OrderCartService.deleteOrderCartItem';
import deleteOrderCart from '@salesforce/apex/OrderCartService.deleteOrderCart';
import submitOrderCarts from '@salesforce/apex/OrderCartService.submitOrderCarts';
import deleteOrderCarts from '@salesforce/apex/OrderCartService.deleteOrderCarts';
import ToastContainer from "lightning/toastContainer";
import Toast from "lightning/toast";
import * as Helper from './helper';

export default class MosaicDirectOrderTable extends LightningElement {
    @track placedOrders = [];
    @track showSavedModal = false;
    @track showFailedModal = false;
    @track orderCounter = 0;
    @track isSubmitting = false;
    @track showDeleteConfirm = false;
    deleteOrderIdPending = null;
    showCancelConfirm = false;
    showSubmitConfirm = false;
    showSuccessPopup = false;

    @api title;
    @api contractId;
    @api maxOrdersDisplay;
    @api showEmptyState;
    @api minDate;
    @api maxDate;
    @api salesOffice;
    @api generateSample(orderId) {
        const items = this.generateSampleOrderItems(orderId);
        return items;
    }

    populateOrderFromCart(data) {
        const carts = data.orderCarts || [];
        const items = data.items || [];

        const itemsByCart = {};
        items.forEach(item => {
            const cartId = item.OrderCart;
            if (!itemsByCart[cartId]) {
                itemsByCart[cartId] = [];
            }

            let tmpReqDate = new Date(item.ReqShipmentDate);
            const displayDate = new Date(tmpReqDate);
            displayDate.setDate(displayDate.getDate() + 1);

            itemsByCart[cartId].push({
                id: item.Id,
                orderCart: cartId,
                contractItem: item.PMC_CPQ_SAPProductCode,
                orderNumber: item.OrderPoNumber,
                orderQty: item.OrderQty,
                uom: item.UOM,
                shipMethod: item.Ship_Method,
                origin: item.Origin,
                originDisplay: item.Origin,
                shipto: item.Ship_To,
                shipToLabel: item.ShipToDisplay,
                subscription: item.Subscription,
                reqShipmentDate: Helper.formatDate(displayDate),
                reqShipmentDateISO: this.toISODateString(tmpReqDate),
            });
        });

        this.placedOrders = carts.map(cart => ({
            id: cart.Id,
            items: itemsByCart[cart.Id]
        }));

        this.calculateTotalsByContractItem();
        this.showToast('Success', 'Order carts loaded successfully!', 'success');
    }

    _newOrderData = null;

    @api
    async loadOrders(recordId) {
        console.log('recordId >>>' + recordId);
        try {
            const data = await getOrderCart({ recordId });
            console.log('data >>> ', data);
            this.populateOrderFromCart(data);
        }
        catch (error) {
            console.error("erro", error);
            this.showToast('Error', 'Failed to load order data', 'error');
        }
    }

    @api
    async refreshOrders() {
        this.placedOrders = [];
        await this.loadOrders();
        this.showToast('Success', 'Orders updated successfully', 'success');
    }

    @api
    set newOrderData(value) {
        console.log('VALOR >>>', value);
        if (!value?.header) return;

        try {
            const {
                // poNumber = '—',
                requestedDate,
                totalQuantity = 1,
                quantityPerLoad = 1,
                oneOrderPerTruck = false,
                contractItem,
                origin,
                originDisplay,
                shipTo,
                shipToLabel,
                shipMethod,
                trucks = 1,
                orderCartId,
                subscription
            } = value.header;

            const items = value.items || [];
            const loadCount = Math.max(trucks, 1);

            const UOM = items[0]?.uom;

            let reqDate;
            if (requestedDate) {
                const [year, month, day] = requestedDate.split('-').map(Number);
                reqDate = new Date(year, month - 1, day);
            } else {
                reqDate = new Date();
            }

            const formattedDate = Helper.formatDate(reqDate);

            const makeItem = (baseId, item, index = 0) => ({
                id: item?.id || `${baseId}-item-${index + 1}`,
                contractItem,
                reqShipmentDate: formattedDate,
                reqShipmentDateISO: this.toISODateString(formattedDate),
                orderNumber: item.orderNumber,
                // orderNumber: poNumber,
                orderQty: quantityPerLoad,
                uom: UOM,
                shipMethod,
                origin: origin,
                originDisplay: originDisplay,
                shipTo,
                shipToLabel,
                subscription
            });

            console.log('origin diaplay >>> ' + originDisplay + ' origin >>>' + origin);

            const orderList = [];

            if (!oneOrderPerTruck) {
                // For single-cart-with-multiple-loads flow, prefer a server-provided orderCartId
                // or fallback to a generated id. Also support header.orderCartIds if modal returned it.
                const orderId = (orderCartId || (value.header && value.header.orderCartIds && value.header.orderCartIds[0])) || `order-${this.orderCounter}-${Date.now()}`;
                const mappedItems = (items.length ? items : Array.from({ length: loadCount })).map((item, i) =>
                    makeItem(orderId, item, i)
                );
                orderList.push({ id: orderId, createdDate: new Date().toISOString(), items: mappedItems });
                this.orderCounter++;
            } else {
                for (let i = 0; i < loadCount; i++) {
                    // For multi-cart flow (oneOrderPerTruck) the modal now provides header.orderCartIds
                    // and each item has an `orderCart` property. Prefer those server ids when present.
                    const orderId = (value.header && value.header.orderCartIds && value.header.orderCartIds[i]) || (items[i] && items[i].orderCart) || orderCartId || `order-${this.orderCounter}-${Date.now()}-${i + 1}`;
                    const item = items[i] || {};
                    orderList.push({
                        id: orderId,
                        createdDate: new Date().toISOString(),
                        items: [makeItem(orderId, item)]
                    });
                    this.orderCounter++;
                }
            }

            const existingIds = new Set(orderList.map(o => o.id));
            this.placedOrders = [
                ...orderList,
                ...this.placedOrders.filter(o => !existingIds.has(o.id))
            ];

            this.showToast(
                'Success',
                `${orderList.length} new ${orderList.length > 1 ? 'orders' : 'order'} added successfully!`,
                'success'
            );
            this.calculateTotalsByContractItem();
        } catch (error) {
            console.error('Error processing newOrderData:', error);
            this.showToast('Error', 'Failed to process new order data', 'error');
        }

        this._newOrderData = value;
    }

    get newOrderData() {
        return this._newOrderData;
    }

    get hasOrders() {
        return this.placedOrders.length > 0;
    }

    get orderCount() {
        return this.placedOrders.length;
    }

    handleCreateOrder() {
        this.orderCounter++;

        const orderId = `order-${this.orderCounter}-${Date.now()}`;

        const newOrder = {
            id: orderId,
            createdDate: new Date().toISOString(),
            items: this.generateSampleOrderItems(orderId)
        };

        this.placedOrders = [newOrder, ...this.placedOrders];

        this.showToast('Success', 'Order created successfully', 'success');
    }

    handleSubmitOrder() {
        // Prevent double submissions
        if (this.isSubmitting) {
            this.showToast('Info', 'Submit already in progress', 'info');
            return;
        }

        // Collect only real Salesforce Ids (15/18 char) to submit
        const cartIds = (this.placedOrders || [])
            .map(o => o.id)
            .filter(id => typeof id === 'string' && /^[0-9A-Za-z]{15,18}$/.test(id));

        if (!cartIds.length) {
            this.showToast('Info', 'No server-backed orders to submit', 'info');
            return;
        }

        // open confirmation modal before submitting
        this._submitCartIds = cartIds;
        this.showSubmitConfirm = true;
        return;
    }

    openSubmitConfirm() {
        const cartIds = (this.placedOrders || [])
            .map(o => o.id)
            .filter(id => typeof id === 'string' && /^[0-9A-Za-z]{15,18}$/.test(id));
        if (!cartIds.length) return this.showToast('Info', 'No server-backed orders to submit', 'info');
        this._submitCartIds = cartIds;
        this.showSubmitConfirm = true;
    }

    backFromSubmitConfirm() {
        this.showSubmitConfirm = false;
    }

    confirmSubmit() {
        // Recompute cartIds from current UI state to ensure we use server-backed OrderCart Ids.
        // Fallback: if an order entry lacks a top-level id, try to read the parent OrderCart id from its first item (item.orderCart)
        const cartIdsSet = new Set();
        (this.placedOrders || []).forEach(o => {
            try {
                if (o && typeof o.id === 'string' && /^[0-9A-Za-z]{15,18}$/.test(o.id)) {
                    //4906
                    // cartIdsSet.add(o.items[0].id);
                    cartIdsSet.add(o.id); // GMDP-3136
                } else if (o && Array.isArray(o.items) && o.items.length > 0) {
                    const first = o.items[0];
                    const candidate = first && (first.orderCart || first.OrderCart || first.orderCartId || first.OrderCart__c);
                    if (candidate && typeof candidate === 'string' && /^[0-9A-Za-z]{15,18}$/.test(candidate)) cartIdsSet.add(candidate);
                }
            } catch (e) { /* defensive: ignore malformed entries */ }
        });
        const cartIds = Array.from(cartIdsSet);
        if (!cartIds.length) {
            this.showSubmitConfirm = false;
            return this.showToast('Info', 'No server-backed orders to submit', 'info');
        }
        this.showSubmitConfirm = false;
        this.isSubmitting = true;
        this.showToast('Info', 'Submitting orders...', 'info');

        // Debug: log the cart ids being submitted so you can inspect in the browser console (F12)
        console.log('Submitting OrderCart ids to server:', cartIds);
        // Extra diagnostic: show a map of orders -> candidate cart id used for submission
        try {
            const debugMap = (this.placedOrders || []).map(o => ({
                orderIdTop: o?.id,
                orderCartIdProp: o?.orderCartId || o?.orderCart,
                firstItemOrderCart: o?.items?.[0]?.orderCart
            }));
            console.log('Submitting OrderCart diagnostics:', debugMap);
        } catch (e) { /* ignore */ }

        submitOrderCarts({ cartIdsJson: JSON.stringify(cartIds) })
            .then(resultMap => {
                console.log('submitOrderCarts resultMap >>>', resultMap);
                // resultMap is expected to be an object mapping cartId -> created Order Id (or null)
                // Mark processed carts as submitted/closed in UI
                const processed = resultMap || {};
                this.placedOrders = this.placedOrders.map(order => {
                    const createdOrderId = processed[order.id];
                    if (createdOrderId) {
                        return { ...order, _isSubmitted: true, status: 'Closed', createdOrderId };
                    }
                    return order;
                });
                this.showToast('Success', 'Orders submitted successfully', 'success');
                // Show the Saved modal when at least one order was created (non-null)

                this.showSuccessPopup = true;

                try {
                    const anyCreated = Object.keys(processed).some(k => processed[k]);
                    if (anyCreated) {
                        // require user to click the close button (no auto-dismiss)
                        this.showSavedModal = true;
                    }
                } catch (e) { /* defensive */ }
            })
            .catch(error => {
                console.error('Submit failed', error);
                this.showToast('Error', 'Failed to submit orders: ' + (error?.body?.message || error.message || error), 'error');
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    openCancelConfirm() {
        // Only open cancel modal if there are orders that have not been submitted (no created Order)
        const cancelable = (this.placedOrders || []).filter(o => !o._isSubmitted && typeof o.id === 'string' && /^[0-9A-Za-z]{15,18}$/.test(o.id));
        if (!cancelable.length) {
            this.showToast('Info', 'No cancellable orders (only orders not yet submitted can be cancelled)', 'info');
            return;
        }
        // store cancelable ids temporarily
        this._cancelableCartIds = cancelable.map(o => o.id);
        this.showCancelConfirm = true;
    }

    backFromCancel() {
        this.showCancelConfirm = false;
    }

    confirmCancel() {
        // use only the cancelable ids computed when opening the modal
        const cartIds = this._cancelableCartIds || [];
        if (!cartIds.length) {
            this.showToast('Info', 'No cancellable orders to cancel', 'info');
            this.showCancelConfirm = false;
            return;
        }

        this.isSubmitting = true;
        deleteOrderCarts({ cartIds })
            .then(result => {
                console.log('deleteOrderCarts result >>>', result);
                if (result) {
                    // remove only cancelled orders from UI
                    const cancelSet = new Set(cartIds);
                    this.placedOrders = (this.placedOrders || []).filter(o => !cancelSet.has(o.id));
                    this.showToast('Success', 'Selected orders cancelled and carts removed', 'success');
                } else {
                    this.showToast('Error', 'Failed to cancel orders', 'error');
                }
            })
            .catch(error => {
                console.error('Cancel failed', error);
                this.showToast('Error', 'Failed to cancel orders: ' + (error?.body?.message || error.message || error), 'error');
            })
            .finally(() => {
                this.isSubmitting = false;
                this.showCancelConfirm = false;
                this._cancelableCartIds = null;
            });
    }

    handleDeleteOrder(event) {
        if (this.isSubmitting) {
            this.showToast('Info', 'Cannot delete while submit is in progress', 'info');
            return;
        }
        const orderIdToDelete = event.currentTarget.dataset.orderId;
        // also prevent deleting already submitted/closed orders
        const order = this.placedOrders.find(o => o.id === orderIdToDelete);
        if (order && order._isSubmitted) {
            this.showToast('Info', 'This order has already been submitted and cannot be deleted', 'info');
            return;
        }
        this.deleteOrderIdPending = orderIdToDelete;
        this.showDeleteConfirm = true;
    }

    cancelDeleteOrder() {
        this.deleteOrderIdPending = null;
        this.showDeleteConfirm = false;
    }

    confirmDeleteOrder() {
        const orderIdToDelete = this.deleteOrderIdPending;
        if (!orderIdToDelete) return;
        this.showDeleteConfirm = false;
        this.deleteOrderIdPending = null;
        deleteOrderCart({ cartId: orderIdToDelete })
            .then(result => {
                if (result) {
                    this.placedOrders = this.placedOrders.filter(order => order.id !== orderIdToDelete);
                    this.showToast('Success', 'Order deleted successfully', 'success');
                    this.calculateTotalsByContractItem();
                } else {
                    this.showToast('Error', 'Failed to delete order', 'error');
                }
            })
            .catch(error => {
                console.error('Failed to delete order', error);
                this.showToast('Error', 'Failed to delete order', 'error');
            });
    }

    handleDeleteItem(event) {
        if (this.isSubmitting) {
            this.showToast('Info', 'Cannot delete item while submit is in progress', 'info');
            return;
        }
        const orderId = event.currentTarget.dataset.orderId;
        const itemIdToDelete = event.currentTarget.dataset.itemId;
        const order = this.placedOrders.find(o => o.id === orderId);
        if (order && order._isSubmitted) {
            this.showToast('Info', 'Cannot delete items for submitted orders', 'info');
            return;
        }
        console.log('event.currentTarget.dataset.itemId >>>' + event.currentTarget.dataset.itemId);
        // If this order only has one item, remove the whole cart when possible
        const itemCount = (order && Array.isArray(order.items)) ? order.items.length : 0;
        if (itemCount === 1) {
            // If this is a server-backed cart (Salesforce Id), call deleteOrderCart which deletes items + cart
            const isServerCart = typeof orderId === 'string' && /^[0-9A-Za-z]{15,18}$/.test(orderId);
            if (isServerCart) {
                deleteOrderCart({ cartId: orderId })
                    .then(result => {
                        if (result) {
                            this.placedOrders = this.placedOrders.filter(o => o.id !== orderId);
                            this.showToast('Success', 'Order and its item deleted successfully', 'success');
                            this.calculateTotalsByContractItem();
                        } else {
                            this.showToast('Error', 'Failed to delete order/cart', 'error');
                        }
                    })
                    .catch(error => {
                        console.error('Failed to delete order/cart', error);
                        this.showToast('Error', 'Failed to delete order/cart', 'error');
                    });
                return;
            } else {
                // Local (client-only) order: just remove the item and the order from UI
                this.placedOrders = this.placedOrders.map(o => {
                    if (o.id === orderId) {
                        const updatedItems = o.items.filter(it => it.id !== itemIdToDelete);
                        return { ...o, items: updatedItems };
                    }
                    return o;
                }).filter(o => o.items && o.items.length > 0);
                this.showToast('Success', 'Order item removed', 'success');
                this.calculateTotalsByContractItem();
                return;
            }
        }

        // Normal case: order has multiple items — delete just the OrderCartItem
        deleteOrderCartItem({ itemId: itemIdToDelete })
            .then(result => {
                if (result) {
                    this.placedOrders = this.placedOrders.map(order => {
                        if (order.id === orderId) {
                            const updatedItems = order.items.filter(item => item.id !== itemIdToDelete);
                            return { ...order, items: updatedItems };
                        }
                        return order;
                    }).filter(order => order.items.length > 0);
                    this.showToast('Success', 'Order item deleted successfully', 'success');
                    this.calculateTotalsByContractItem();
                } else {
                    this.showToast('Error', 'Failed to delete item', 'error');
                }
            })
            .catch(error => {
                console.error('Delete failed', error);
                this.showToast('Error', 'Failed to delete item', 'error');
            });

    }

    handleEditItem(event) {
        if (this.isSubmitting) {
            this.showToast('Info', 'Cannot edit while submit is in progress', 'info');
            return;
        }
        const orderId = event.currentTarget.dataset.orderId;
        const itemIdToEdit = event.currentTarget.dataset.itemId;

        this.placedOrders = this.placedOrders.map(order => {
            if (order.id === orderId) {
                if (order._isSubmitted) return order;
                const items = order.items.map(item => {
                    if (item.id === itemIdToEdit) {
                        return {
                            ...item,
                            _isEditing: true,
                            _originalQty: item.orderQty,
                            _validationOrderQty: null,
                            _validationOrderNumber:null,
                            _editValues: {
                                orderQty: item.orderQty,
                                orderNumber: item.orderNumber,
                                reqShipmentDateISO: item.reqShipmentDateISO || this.toISODateString(item.reqShipmentDate)
                            }
                        };
                    }
                    return item;
                });
                return { ...order, items };
            }
            return order;
        });
    }

    handleFieldChange(event) {
        const orderId = event.target.dataset.orderId;
        const itemId = event.target.dataset.itemId;
        const fieldValue = event.target.value;
        const fieldName = this.getFieldNameFromInput(event.target);

        this.placedOrders = this.placedOrders.map(order => {
            if (order.id === orderId) {
                const items = order.items.map(item => {
                    if (item.id === itemId) {
                        const editValues = { ...(item._editValues || {}) };
                        let validationOrderQty = item._validationOrderQty || null;
                        let validationOrderNumber=item._validationOrderNumber || null;
                        let validationDate=item._validationDate ||null;
                        let selectedDate = null;
                    //GSMD-5032
                        if (fieldName === 'reqShipmentDateISO') {
                             const today1 = new Date();
            today1.setHours(0, 0, 0, 0);
            selectedDate = new Date(fieldValue + 'T00:00:00');
                                if (isNaN(selectedDate.getTime()) || selectedDate < today1) {
        
                                validationDate = 'Shipment date cannot be in the past';
                            } else {
                                validationDate = null;
                            }
                
            
                            editValues.reqShipmentDateISO = fieldValue || '';
                            return { ...item, _editValues: editValues, _validationOrderQty: validationOrderQty,_validationOrderNumber:validationOrderNumber, _validationDate:validationDate };
                        }

                        if (fieldName === 'orderQty') {
                            const num = parseFloat(fieldValue);
                            const originalQty = parseFloat(item._originalQty || item.orderQty); // valor inicial

                            if (!fieldValue || isNaN(num) || num <= 0) {
                                validationOrderQty = 'Please enter a quantity greater than 0';
                            } else if (num > originalQty) {
                                validationOrderQty = 'Quantity cannot be greater than current value';
                            } else {
                                validationOrderQty = null;
                            }

                            editValues.orderQty = fieldValue;
                        }

                        if (fieldName === 'orderNumber') {
                            if( fieldValue.length > 35)
                     {

                    validationOrderNumber = 'Maximum 35 characters allowed';
                            }
                             else {
                                validationOrderNumber = null;
                            }
                            editValues.orderNumber = fieldValue;
                        }

                        return {
                            ...item,
                            orderQty: editValues.orderQty !== undefined ? editValues.orderQty : item.orderQty,
                            //GSMD 4906
                            orderNumber: editValues.orderNumber !== undefined ? editValues.orderNumber : item.orderNumber,

                            _editValues: editValues,
                            _validationOrderQty: validationOrderQty,
                           _validationOrderNumber :validationOrderNumber,
                           _validationDate:validationDate
                        };
                    }
                    return item;
                });
                return { ...order, items };
            }
            //GSMD 4906
            console.log('order1 Data : ', order);
            return order;
        });
    }

    handleSaveItem(event) {
        const orderId = event.currentTarget.dataset.orderId;
        const itemId = event.currentTarget.dataset.itemId;

        if (this.isSubmitting) {
            this.showToast('Info', 'Cannot save while submit is in progress', 'info');
            return;
        }

        const order = this.placedOrders.find(o => o.id === orderId);
        if (!order || order._isSubmitted || !order.items) return;

        const item = order.items.find(i => i.id === itemId);
        if (!item) return;

        const edits = item._editValues || {};
        const candidateQty = edits.orderQty !== undefined ? edits.orderQty : item.orderQty;
        const num = parseFloat(candidateQty);
        const originalQty = parseFloat(item._originalQty || item.orderQty);
        const ordernumtemp =item.orderNumber || item._orderNumber;
        if(ordernumtemp.length>35)
        {
            this.setValidationErrororderNumber(orderId, itemId, 'Maximum 35 characters allowed');
            this.showToast('Error', 'Maximum 35 characters allowed', 'error');
            return;
        }

        if (!candidateQty || isNaN(num) || num <= 0) {
            this.setValidationError(orderId, itemId, 'Please enter a quantity greater than 0');
            this.showToast('Error', 'Please enter a quantity greater than 0', 'error');
            return;
        }

        if (num > originalQty) {
            this.setValidationError(orderId, itemId, 'Quantity cannot be greater than current value');
            this.showToast('Error', 'Quantity cannot be greater than current value', 'error');
            return;
        } 
      

        const editedIsoPresent = Object.prototype.hasOwnProperty.call(edits, 'reqShipmentDateISO');
        let isoDate = editedIsoPresent ? (edits.reqShipmentDateISO || '') : undefined;
        let selectedDate = null;

        // When user edited the date field, the date becomes required and must be validated
        if (editedIsoPresent) {
            if (!isoDate) {
                this.showToast('Error', 'Shipment date is required', 'error');
                return;
            }

            const today = new Date();
            today.setHours(0, 0, 0, 0);
            selectedDate = new Date(isoDate + 'T00:00:00');

            if (isNaN(selectedDate.getTime()) || selectedDate < today) {
                this.showToast('Error', 'Shipment date cannot be in the past', 'error');
                return;
            }

            try {
                if (Helper && Helper.DateHelper && typeof Helper.DateHelper.isBusinessDay === 'function') {
                    const isBiz = Helper.DateHelper.isBusinessDay(isoDate, this.salesOffice);
                    if (!isBiz) {
                        this.showToast('Error', 'Shipment date must be a business day (Monday to Friday)', 'error');
                        return;
                    }
                } else {
                    if (selectedDate.getDay() === 0 || selectedDate.getDay() === 6) {
                        this.showToast('Error', 'Shipment date must be a business day (Monday to Friday)', 'error');
                        return;
                    }
                }
            } catch (e) {
                if (selectedDate.getDay() === 0 || selectedDate.getDay() === 6) {
                    this.showToast('Error', 'Shipment date must be a business day (Monday to Friday)', 'error');
                    return;
                }
            }

            if (this.minDate) {
                const minObj = new Date(this.minDate + 'T00:00:00');
                if (!isNaN(minObj.getTime()) && selectedDate < minObj) {
                    this.showToast('Error', `Shipment date must be on or after ${this.minDate}`, 'error');
                    return;
                }
            }
            if (this.maxDate) {
                const maxObj = new Date(this.maxDate + 'T00:00:00');
                if (!isNaN(maxObj.getTime()) && selectedDate > maxObj) {
                    this.showToast('Error', `Shipment date must be on or before ${this.maxDate}`, 'error');
                    return;
                }
            }
        }

        const payload = {
            Id: item.id,
            orderQty: num,
            orderNumber: edits.orderNumber !== undefined ? edits.orderNumber : item.orderNumber
        };
        if (editedIsoPresent) payload.reqShipmentDate = isoDate || null;

        updateOrderCartItem({ itemJson: JSON.stringify(payload) })
            .then(() => {
                this.placedOrders = this.placedOrders.map(o => {
                    if (o.id === orderId) {
                        const items = o.items.map(it => {
                            if (it.id === itemId) {
                                return {
                                    ...it,
                                    orderQty: num,
                                    orderNumber: payload.orderNumber,
                                    reqShipmentDate: editedIsoPresent ? (selectedDate ? Helper.formatDate(selectedDate) : '') : it.reqShipmentDate,
                                    reqShipmentDateISO: editedIsoPresent ? (isoDate || '') : it.reqShipmentDateISO,
                                    _isEditing: false,
                                    _editValues: null,
                                    _validationOrderQty: null,
                                    _validationOrderNumber:null,
                                    _originalQty: undefined
                                };
                            }
                            return it;
                        });
                        return { ...o, items };
                    }
                    return o;
                });

                this.showToast('Success', 'Item saved successfully', 'success');
                this.calculateTotalsByContractItem();
            })
            .catch(error => {
                console.error('Failed to save item', error);
                this.showToast('Error', 'Failed to save item', 'error');
            });
    }

    setValidationError(orderId, itemId, message) {
        this.placedOrders = this.placedOrders.map(order => {
            if (order.id === orderId) {
                const items = order.items.map(it => {
                    if (it.id === itemId) {
                        return { ...it, _validationOrderQty: message};
                    }
                    return it;
                });
                return { ...order, items };
            }
            return order;
        });
    }
    setValidationErrororderNumber(orderId, itemId, message) {
        this.placedOrders = this.placedOrders.map(order => {
            if (order.id === orderId) {
                const items = order.items.map(it => {
                    if (it.id === itemId) {
                        return { ...it, _validationOrderNumber:message};
                    }
                    return it;
                });
                return { ...order, items };
            }
            return order;
        });
    }

    handleCancelEdit(event) {
        const orderId = event.currentTarget.dataset.orderId;
        const itemId = event.currentTarget.dataset.itemId;

        this.placedOrders = this.placedOrders.map(order => {
            if (order.id === orderId) {
                const items = order.items.map(item => {
                    if (item.id === itemId) {
                        return { ...item, _isEditing: false, _editValues: null, _validationOrderQty: null };
                    }
                    return item;
                });
                return { ...order, items };
            }
            return order;
        });
    }

    getFieldNameFromInput(target) {
        const type = target.type;
        if (type === 'date') return 'reqShipmentDateISO';
        if (type === 'number') return 'orderQty';
        return 'orderNumber';
    }

    toISODateString(displayDate) {
        if (!displayDate) return '';
        let str = String(displayDate).trim();
        let date;

        if (str.includes('-')) {
            date = new Date(str);
        } else {
            let [mm, dd, yy] = str.split('/').map(Number);
            let year = yy < 100 ? 2000 + yy : yy;
           // GSMD-5157
            date = new Date(year, mm - 1, dd+1);
        }

        if (isNaN(date.getTime())) return '';

        // date.setDate(date.getDate() + 1);

        return date.toISOString().slice(0, 10);
    }

    // showToast(toastTitle, toastMessage, toastVariant) {
    //     const event = new ShowToastEvent({
    //         title: toastTitle,
    //         message: toastMessage,
    //         variant: toastVariant
    //     });
    //     this.dispatchEvent(event);
    // }

    connectedCallback() {
        console.log('Order Manager component initialized');

        let toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        toastContainer.toastPosition = "top-center";
    }

    disconnectedCallback() {
        console.log('Order Manager component disconnected');
    }

    closeSavedModal() {
        try {
            this.showSavedModal = false;
        } catch (e) { /* ignore */ }
    }

    closeSuccessModal() {
        window.location.reload();
    }

    closeFailedModal() {
        try { this.showFailedModal = false; } catch (e) { /* ignore */ }
    }

    calculateTotalsByContractItem() {
        const totals = {};

        (this.placedOrders || []).forEach(order => {
            (order.items || []).forEach(item => {
                const key = item.subscription;
                const qty = parseFloat(item.orderQty) || 0;
                totals[key] = (totals[key] || 0) + qty;
            });
        });

        this.dispatchEvent(
            new CustomEvent('ordertotalschange', {
                detail: { totalsByItem: totals }
            })
        );
        console.log('totals >>>', totals);
        return totals;
    }

    showToast(label, message, variant = "info") {
        Toast.show({ label, message, variant, mode: 'dismissible' }, this);
    }
}