import pmc_contractDetails_products from "@salesforce/label/c.pmc_contractDetails_products";

export const productCategories = (experienceCloudNavMenu) => {
    
      let submenu=[];
      const productMenuItem = experienceCloudNavMenu.menuItems.find(item => item.label === pmc_contractDetails_products);
      const subMenu = productMenuItem ? productMenuItem.subMenu : null;
      subMenu.forEach((item) => {
        if (item.label && item.actionValue) {          
          submenu.push({
            label: item.label,
            value: item.actionValue.replace("/digitalhub", "")
          });
        }
      });
      return submenu;
}