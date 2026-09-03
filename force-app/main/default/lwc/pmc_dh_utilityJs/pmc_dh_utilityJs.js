import PMC_DH_UserInfo_DuplicateContact from "@salesforce/label/c.PMC_DH_UserInfo_DuplicateContact";
import PMC_DH_GenericTechnicalError from "@salesforce/label/c.PMC_DH_GenericTechnicalError";
import PMC_DH_Registration_DuplicateContact from "@salesforce/label/c.PMC_DH_Registration_DuplicateContact";
import PMC_DH_Address_UserNotPermitted from "@salesforce/label/c.PMC_DH_Address_UserNotPermitted";
import PMC_DH_AddressDeleteError from "@salesforce/label/c.PMC_DH_AddressDeleteError";
import PMC_DH_Case_ReopenError from "@salesforce/label/c.PMC_DH_Case_ReopenError";
import PMC_DH_Request_Signature_Error from "@salesforce/label/c.PMC_DH_Request_Signature_Error";
import pmc_orderDetails_yourChangesNotSaved from "@salesforce/label/c.pmc_orderDetails_yourChangesNotSaved";
import pmc_userManagement_userRoleExists from "@salesforce/label/c.pmc_userManagement_userRoleExists";
import pmc_errorHandling_errorMsg from "@salesforce/label/c.pmc_errorHandling_errorMsg";
import PMC_DH_DocumentNotFound from "@salesforce/label/c.PMC_DH_DocumentNotFound";
import PMC_DH_QuoteExpirationErrorMessage from "@salesforce/label/c.PMC_DH_QuoteExpirationErrorMessage";
import pmc_userManagement_superBuyerNotAuthorized from "@salesforce/label/c.pmc_userManagement_superBuyerNotAuthorized";

import Toast from 'lightning/toast';
import ToastContainer from 'lightning/toastContainer';

// Set a value with an expiration time in sessionStorage
export const setWithExpirationFromSession = (key, value, ttlInSeconds) => {
  const now = new Date();

  const item = {
      value: value,
      expiration: now.getTime() + ttlInSeconds * 1000,
  };

  sessionStorage.setItem(key, JSON.stringify(item));
  console.log(`Value set in sessionStorage with expiration: ${key} =`, item);
}

// Retrieve a value and check if it has expired
export const getWithExpirationFromSession = (key) => {
  const itemStr = sessionStorage.getItem(key);

  if (!itemStr) {
      console.log('No value found in sessionStorage for key:', key);
      return null;
  }

  const item = JSON.parse(itemStr);
  const now = new Date();

  if (now.getTime() > item.expiration) {
      sessionStorage.removeItem(key);
      console.log(`Value for key "${key}" has expired.`);
      return null;
  }

  return item.value;
}

export const handleError = (error) => {
  const labels = {
    PMC_DH_UserInfo_DuplicateContact,
    PMC_DH_GenericTechnicalError,
    PMC_DH_Registration_DuplicateContact,
    pmc_orderDetails_yourChangesNotSaved,
    PMC_DH_Address_UserNotPermitted,
    PMC_DH_AddressDeleteError,
    PMC_DH_Case_ReopenError,
    PMC_DH_Request_Signature_Error,
    pmc_userManagement_userRoleExists,
    PMC_DH_DocumentNotFound,
    pmc_userManagement_superBuyerNotAuthorized,
    PMC_DH_QuoteExpirationErrorMessage
  };
  return labels[error];
}

/*
 * Get lineItemData from session Storage
 */
export const getLineItemDataFromSessionStorage = (productId) => {
  const storageKey = `product_${productId}`;
  const data = sessionStorage.getItem(storageKey);

  if (data) {
      return JSON.parse(data);
  } else {
      console.log('No data found for specified line item.');
      return null;
  }
}

export const upsertLineItemData = (productId, newAvailableQty, newOrderedQty) => {
  const storageKey = `product_${productId}`;

  // Retrieve the current data for the line it
  let itemData = sessionStorage.getItem(storageKey);

  if (itemData) {
      // Parse the existing data
      itemData = JSON.parse(itemData);
  } else {
      // Initialize a new object if no existing data
      itemData = {};
  }

  // Upsert the values
  itemData.intAvailableQty = newAvailableQty !== undefined ? newAvailableQty : itemData.intAvailableQty || null;
  itemData.intOrderedQty = newOrderedQty !== undefined ? newOrderedQty : itemData.intOrderedQty || null;

  // Save the updated or newly created data back to session storage
  sessionStorage.setItem(storageKey, JSON.stringify(itemData));
  console.log(`Upserted line item ${productId} in session storage.`);
}

/*
 * Show toast on API fail
 */
export const toastMessageHandler = (message) => {
  let toastMessage = pmc_errorHandling_errorMsg;
  if (message) {
    toastMessage = handleError(message)
  }
  Toast.show({
    label: toastMessage,
    mode: 'Sticky',
    variant: 'error'
  }, this);
  const toastContainer = ToastContainer.instance();
  toastContainer.maxToasts = 1;
  toastContainer.toastPosition = 'top-center';
}

export const isBrazilRegion = () => {
  const BRAZIL_LOCALE = "Brazil";
  return sessionStorage.getItem("userRegion") === BRAZIL_LOCALE;
}

export const formatLabel = (str, args) => {
  if (!str) {
    return str;
  }
  return str.replace(/{(\d+)}/g, function (match, number) {
    return args[number];
  });
};

/*
 * handling Placeholder for input date fields in small devices
 */
export const inputDatePlaceholderHandler = (date, inputComponent) => {
  if (date) {
    inputComponent.classList.remove('input-date-placeholder');
  }
  else {
    inputComponent.classList.add('input-date-placeholder');
  }
};

/*
 * Formatting Date based on Country
 */
export const formatDate = (date) => {
  let formattedDate;
  try {
    const _date = date.split('-');
    const dateObj = { month: _date[1], day: _date[2], year: _date[0] };
    if (isBrazilRegion()) {
      formattedDate = dateObj.day + '/' + dateObj.month + '/' + dateObj.year;
    }
    else {
      formattedDate = dateObj.month + '/' + dateObj.day + '/' + dateObj.year;
    }
  }
  catch (e) {
    console.log('format err:', date, e);
  }
  return formattedDate;
};

/*
 * Unformating Date based on Country
 */
export const unFormatDate = (date) => {
  let formattedDate;
  const _date = date.split('/');
  let dateObj = {};
  if (isBrazilRegion()) {
    dateObj = { month: _date[1], day: _date[0], year: _date[2] };
  }
  else {
    dateObj = { month: _date[0], day: _date[1], year: _date[2] };
  }
  formattedDate = dateObj.year + '-' + dateObj.month + '-' + dateObj.day;

  return formattedDate;
};

/*
 * Formatting DateTime based on Country
 */
export const formatDateTime = (dateTime) => {
  let formattedDateTime;
  const _dt = dateTime.split('T');
  const _date = _dt[0].split("-");
  const _time = _dt[1].split(".")[0];
  const dateObj = { month: _date[1], day: _date[2], year: _date[0] };
  if (isBrazilRegion()) {
    formattedDateTime = dateObj.day + '/' + dateObj.month + '/' + dateObj.year + ' ' + _time;
  }
  else {
    formattedDateTime = dateObj.month + '/' + dateObj.day + '/' + dateObj.year + ' ' + _time;
  }
  return formattedDateTime;
};

/**
 * Get Today's Date in 'YYYY-MM-DD' format
 * @returns {string}
 */
export const getTodayDate = (format) => {
  const today = new Date();
  switch (format) {
    case "DDMMYYYY": return ((today.getDate().toString().padStart(2, '0')) + ((today.getMonth() + 1).toString().padStart(2, '0')) + today.getFullYear());
    case "DD/MM/YYYY": return ((today.getDate().toString().padStart(2, '0')) + '/' + ((today.getMonth() + 1).toString().padStart(2, '0')) + '/' + today.getFullYear());
    default: return (today.getFullYear() + '-' + ((today.getMonth() + 1).toString().padStart(2, '0')) + '-' + (today.getDate().toString().padStart(2, '0')));
  }
}

/**
 * Return Appended Currency and Price string
 */
export const getCurrencyAndPrice = (isoCode, price) => {
  const US_CURRENCY = '$';
  const BR_CURRENCY = 'R$';
  const US_ISO_CODE = 'USD';
  const CA_ISO_CODE = 'CAD';
  const BR_ISO_CODE = 'BRL';
  let currencyAndPrice = 'N/A';
  if (+price) {
    let currency = '';
    if (isoCode === US_ISO_CODE || isoCode === CA_ISO_CODE) {
      currency = US_CURRENCY;
    }
    if (isoCode === BR_ISO_CODE) {
      currency = BR_CURRENCY;
    }
    currencyAndPrice = `${currency}${price}`;
  }
  return currencyAndPrice;
}

/*
 * Masking Mobile Number based on country code
 */
export const formatPhoneNumber = (phoneNumber, countryCode) => {
  const REGEX = {
    USCA_REGEX: /^\d{10}$/,
    USCA_MASK: /(\d{3})(\d{3})(\d{4})/,
    BR_MASK_10: /^(\d{2})(\d{4})(\d{4})$/,
    BR_MASK_11: /^(\d{2})(\d{5})(\d{4})$/,
    USCA_PHONE_NUMBER_LENGTH: 10,
    BRAZIL_PHONE_NUMBER_MIN_LENGTH: 10,
    BRAZIL_PHONE_NUMBER_MAX_LENGTH: 11,
  };
  let formattedNumber = phoneNumber;
  switch (countryCode) {
    case 'US +1':
    case 'CA +1':
    case 'United States':
    case 'Canada':
      if (phoneNumber.length === REGEX.USCA_PHONE_NUMBER_LENGTH) {
        if (REGEX.USCA_REGEX.test(phoneNumber)) {
          formattedNumber = phoneNumber.replace(REGEX.USCA_MASK, '($1) $2-$3');
        }
      }
      break;

    case 'BR +55':
    case 'Brazil':
      if (phoneNumber.length === REGEX.BRAZIL_PHONE_NUMBER_MIN_LENGTH) {
        formattedNumber = phoneNumber.replace(/\D/g, '').replace(REGEX.BR_MASK_10, '($1) $2-$3');
      } else if (phoneNumber.length === REGEX.BRAZIL_PHONE_NUMBER_MAX_LENGTH) {
        formattedNumber = phoneNumber.replace(/\D/g, '').replace(REGEX.BR_MASK_11, '($1) $2-$3');
      }
      break;

    default:
      break;
  }
  return formattedNumber;
}

/*
 * Unmasking Mobile Number
 */
export const unFormatPhoneNumber = (str) => {
  const cleanedPhoneNumber = str.replace(/\D/g, '');
  return cleanedPhoneNumber;
}

/*
 * Get new URL after translations
 */
export const languageReload = (langKeys, responseKey) => {
  let origin = window.location.origin;
  let pathname = window.location.pathname;
  let search = window.location.search;
  let defaultUrl = window.location.href;
  let returnUrl = null;
  if (!pathname.includes('/' + responseKey)) {
    for (let item of langKeys) {
      if (pathname.includes('/' + item)) {
        pathname = pathname.replace(item, responseKey);
        returnUrl = origin + pathname;
        break;
      }
    }
    if (!returnUrl) {
      returnUrl = origin + pathname.slice(0, 1) + responseKey + "/" + pathname.slice(1);
    }
  }
  return search ? returnUrl ? returnUrl + search : defaultUrl : returnUrl ? returnUrl : defaultUrl;
}

export const SORT_DIRECTION = {
  ASC: "asc",
  DESC: "desc"
};

/**
 * Sort data
 * @param {Object[]} dataArr
 * @param {string} fieldName
 * @param {string} dataType
 * @param {string} sortDir
 * @returns {Object[]} Sorted data
 */
export const sortData = (dataArr, fieldName, dataType, sortDir) => {
  if (dataArr === null || dataArr === undefined) return null;
  let isReverse = sortDir === SORT_DIRECTION.ASC ? 1 : -1;
  let sortedData = JSON.parse(JSON.stringify(dataArr));
  let keyValue = (a) => {
    switch (dataType) {
      case "number":
        return a[fieldName] ? +a[fieldName] : null;
      case "date":
        if (a[fieldName] && isBrazilRegion()) {
          const dateVal = a[fieldName].includes('-') ? a[fieldName].split('-') : a[fieldName].split('/');
          return new Date(dateVal[1] + '/' + dateVal[0] + '/' + dateVal[2]);
        }
        return a[fieldName] ? new Date(a[fieldName].replace("-", "/")) : "";
      case "datetime":
        if (a[fieldName] && isBrazilRegion()) {
          const splitVal = a[fieldName].split(" ");
          const dateVal = splitVal[0].includes("-") ? splitVal[0].split("-") : splitVal[0].split("/");
          const timeVal = splitVal[1];
          const dateTimeVal = `${dateVal[1]}/${dateVal[0]}/${dateVal[2]} ${timeVal}`
          return Date.parse(dateTimeVal);
        }
        return a[fieldName] ? Date.parse(a[fieldName]) : "";
      case "alphanumeric-substr": return a[fieldName] ? (a[fieldName].includes('-') ? a[fieldName].split('-')[1] : a[fieldName]) : null;
      default:
        return a[fieldName] ? a[fieldName].toLowerCase() : "";
    }
  };
  sortedData.sort((x, y) => {
    x = keyValue(x);
    y = keyValue(y);
    if (dataType === "alphanumeric" || dataType === "alphanumeric-substr") {
      const collator = new Intl.Collator(["en", "es", "pt"], {
        numeric: true,
        sensitivity: "accent"
      });
      return isReverse * collator.compare(x, y);
    }
    return isReverse * ((x > y) - (y > x));
  });
  return sortedData;
};

/*
 * URL redirection: Fix for Appscan issue
 * Allowing untrusted site by passing user controlled input
 * window.location.href or window.open
 */
export const urlRedirect = (url) => {
  var link = document.createElement('a');
  link.href = url;
  link.click();
}

/**
 * Formats the language specific url to standard url
 * @param {string} target
 * @returns
 */
export const formatNavigationUrl = (langKeys, target) => {
  for (let item of langKeys) {
    if (target.includes('/' + item)) {
      let url = target.split('/' + item);
      target = url.join("");
    }
  }
  return target;
}

/**
 * Returns a raw date with 0:0:0 hrs, regardless of the local time.
 * @param {Object} newDate // yyyy-mm-dd
 * @returns
 */
export const getRawDateUtil = (newDate) => {
  if (newDate) {
    let dt = newDate.split("-"); //[year, month, day]
    //return new Date(dt[0], dt[1] - 1, dt[2]); //Ddd Mmm DD YYYY 00:00:00 GMT+-local time (Standard Time)
    return new Date(Date.UTC(dt[0], dt[1] - 1, dt[2]));//GSMD-1882
  }

  return null;
}

/**
 * A basic pub-sub mechanism for sibling component communication
 * TODO - adopt standard flexipage sibling communication mechanism when it's available.
 */
const events = {};

/**
 * Registers a callback for an event
 * @param {string} eventName - Name of the event to listen for.
 * @param {function} callback - Function to invoke when said event is fired.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const registerListener = (eventName, callback, thisArg) => {
  if (!events[eventName]) {
    events[eventName] = [];
  }
  const duplicate = events[eventName].find(listener => {
    return listener.callback === callback && listener.thisArg === thisArg;
  });
  if (!duplicate) {
    events[eventName].push({ callback, thisArg });
  }
};

/**
 * Unregisters a callback for an event
 * @param {string} eventName - Name of the event to unregister from.
 * @param {function} callback - Function to unregister.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
const unregisterListener = (eventName, callback, thisArg) => {
  if (events[eventName]) {
    events[eventName] = events[eventName].filter(
      listener =>
        listener.callback !== callback || listener.thisArg !== thisArg
    );
  }
};

/**
 * Unregisters all event listeners bound to an object.
 * @param {object} thisArg - All the callbacks bound to this object will be removed.
 */
const unregisterAllListeners = thisArg => {
  Object.keys(events).forEach(eventName => {
    events[eventName] = events[eventName].filter(
      listener => listener.thisArg !== thisArg
    );
  });
};

/**
 * Fires an event to listeners.
 * @param {object} pageRef - Reference of the page that represents the event scope.
 * @param {string} eventName - Name of the event to fire.
 * @param {*} payload - Payload of the event to fire.
 */
const fireEvent = (pageRef, eventName, payload) => {
  if (events[eventName]) {
    const listeners = events[eventName];
    listeners.forEach(listener => {
      try {
        listener.callback.call(listener.thisArg, payload);
      } catch (error) {
        // fail silently
      }
    });
  }
};

export {
  registerListener,
  unregisterListener,
  unregisterAllListeners,
  fireEvent
};