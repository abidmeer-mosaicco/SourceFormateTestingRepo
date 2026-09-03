export function isBusinessDay(dateStr, salesOffice) {
    if (!dateStr) return false;

   let normalizedSalesOffice = salesOffice.toUpperCase().replace(/-/g, '- ').trim();
  //  if (normalizedSalesOffice.includes('US All Raw Materials')) return true;
 
  if (normalizedSalesOffice.includes('US ALL RAW MATERIALS')) return true;


    // let dias = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
    let localDateStr = dateStr.split('T')[0];
    let today = new Date(localDateStr);
    let dayNumber = today.getDay() + 1;

    // console.log({ dayNumber });
    // console.log({ diaAtual: dias[dayNumber] });
    // console.log({ check: dayNumber >= 1 && dayNumber <= 5 && !isNaN(d.getTime()) });

    return dayNumber >= 1 && dayNumber <= 5 && !isNaN(today.getTime());
}

export function getLeadTimeDays(salesOffice, incoterm) {
    const incotermUpper = (incoterm || '').toUpperCase().trim();

    let normalizedSalesOffice = salesOffice.toUpperCase().replace(/-/g, '- ').trim();
    console.log({ normalizedSalesOffice })

    if (normalizedSalesOffice.includes('US AND CA ALL INDUSTRIAL')) {
        return 5;
    }

    if (normalizedSalesOffice.includes('US ALL RAW MATERIALS')) {
        return 0;
    }

    if (normalizedSalesOffice.includes('US AND CA EAST FERTILIZER') || normalizedSalesOffice.includes('US AND CA WEST FERTILIZER') || normalizedSalesOffice.includes('US AND CA ALL FEED')) {
        if (['FCA', 'FOB'].includes(incotermUpper)) {
            return 0;
        } else if (['CPT', 'CFR'].includes(incotermUpper)) {
            return 3;
        }
    }

    return 0;
}

export function getEarliestShipmentDate(salesOffice, incoterm) {
    const todayStr = new Date().toISOString().split('T')[0];
    const leadDays = getLeadTimeDays(salesOffice, incoterm);
    let currentDate = new Date(todayStr);
    if (leadDays === 0) {
        if (isBusinessDay(todayStr, salesOffice)) {
            return todayStr;
        } else {
            while (!isBusinessDay(currentDate.toISOString().split('T')[0], salesOffice)) {
                currentDate.setDate(currentDate.getDate() + 1);
            }

            return currentDate.toISOString().split('T')[0];
        }
    } else {
        let businessDaysAdded = 0;
        while (businessDaysAdded < leadDays) {
            currentDate.setDate(currentDate.getDate() + 1);
            if (isBusinessDay(currentDate.toISOString().split('T')[0], salesOffice)) {
                businessDaysAdded++;
            }
        }

        return currentDate.toISOString().split('T')[0];
    }
}

export function getFirstBusinessDayOnOrAfter(dateStr) {
    if (!dateStr) return null;
    let d = new Date(dateStr);
    let day = d.getDay();

    if (day === 0) {
        d.setDate(d.getDate() + 1);
    } else if (day === 6) {
        d.setDate(d.getDate() + 2);
    }

    return d.toISOString().split('T')[0];
}

export function getLastBusinessDayOnOrBefore(dateStr) {
    if (!dateStr) return null;
    let d = new Date(dateStr);
    let day = d.getDay();

    if (day === 0) {
        d.setDate(d.getDate() - 2);
    } else if (day === 6) {
        d.setDate(d.getDate() - 1);
    }

    return d.toISOString().split('T')[0];
}