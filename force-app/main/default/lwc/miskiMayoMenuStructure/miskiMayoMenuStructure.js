import { LightningElement, track } from 'lwc';
import CARD_IMAGES from '@salesforce/resourceUrl/miskiMayoIcon';
import MM_BASEURL from '@salesforce/label/c.MM_BASEURL';
import MM_CONOCENOS_NOSOTROS from '@salesforce/label/c.MM_CONOCENOS_NOSOTROS';
import MM_CONOCENOS_ACCIONISTAS from '@salesforce/label/c.MM_CONOCENOS_ACCIONISTAS';
import MM_CONOCENOS_LIDERES from '@salesforce/label/c.MM_CONOCENOS_LIDERES';
import MM_CONOCENOS_PREMIOS from '@salesforce/label/c.MM_CONOCENOS_PREMIOS';
import MM_PROCESO_PRODUCTIVO from '@salesforce/label/c.MM_PROCESO_PRODUCTIVO';
import MM_HACEMOS_MINERIA_VERDE from '@salesforce/label/c.MM_HACEMOS_MINERIA_VERDE';
import MM_NUESTRO_PRODUCTO from '@salesforce/label/c.MM_NUESTRO_PRODUCTO';
import MM_GESTION_SOCIAL from '@salesforce/label/c.MM_GESTION_SOCIAL';
import MM_COMPROMISOS_CONTRACTUALES from '@salesforce/label/c.MM_COMPROMISOS_CONTRACTUALES';
import MM_PROGRAMAS_SOCIALES from '@salesforce/label/c.MM_PROGRAMAS_SOCIALES';
import MM_PROVEDORES_CONTRATISTAS from '@salesforce/label/c.MM_PROVEDORES_CONTRATISTAS';
import MM_SEGURIDAD from '@salesforce/label/c.MM_SEGURIDAD';
import MM_SISTEMA_INTEGRAL_DE_GESTION from '@salesforce/label/c.MM_SISTEMA_INTEGRAL_DE_GESTION';
import MM_9REGLAS_PARA_SALVAGUARDAR_VIDAS from '@salesforce/label/c.MM_9REGLAS_PARA_SALVAGUARDAR_VIDAS';
import MM_HERRAMIENTAS_DE_GESTION from '@salesforce/label/c.MM_HERRAMIENTAS_DE_GESTION';
import MM_SALUD from '@salesforce/label/c.MM_SALUD';
import MM_GESTION_AMBIENTAL from '@salesforce/label/c.MM_GESTION_AMBIENTAL';
import MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS from '@salesforce/label/c.MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS';
import MM_PROGRAMA_DE_MONITOREO_AMBIENTAL from '@salesforce/label/c.MM_PROGRAMA_DE_MONITOREO_AMBIENTAL';
import MM_PLAN_DE_CIERRE_DE_MINA from '@salesforce/label/c.MM_PLAN_DE_CIERRE_DE_MINA';
import MM_POLITICA_SIG_Y_POLITICA_SSMA from '@salesforce/label/c.MM_POLITICA_SIG_Y_POLITICA_SSMA';
import MM_ETICA_Y_CUMPLIMIENTO from '@salesforce/label/c.MM_ETICA_Y_CUMPLIMIENTO';
import MM_PREVENCION_DE_LA_DISCRIMINACION from '@salesforce/label/c.MM_PREVENCION_DE_LA_DISCRIMINACION';
import MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR from '@salesforce/label/c.MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR';
import MM_DIVERSIDAD_E_INCLUSION from '@salesforce/label/c.MM_DIVERSIDAD_E_INCLUSION';
import MM_NOTAS_DE_PRENSA from '@salesforce/label/c.MM_NOTAS_DE_PRENSA';
import MM_RESENAS_INSTITUCIONALES from '@salesforce/label/c.MM_RESENAS_INSTITUCIONALES';
import MM_BOLETINES from '@salesforce/label/c.MM_BOLETINES';
import MM_OTRAS_PUBLICACIONES from '@salesforce/label/c.MM_OTRAS_PUBLICACIONES';
import MM_REGISTRA_TU_CONSULTA from '@salesforce/label/c.MM_REGISTRA_TU_CONSULTA';
import MM_PREGUNTAS_FREQUENTES from '@salesforce/label/c.MM_PREGUNTAS_FREQUENTES';
import MM_TRABAJA_CON_NOSOTROS from '@salesforce/label/c.MM_TRABAJA_CON_NOSOTROS';
import MM_PROVEEDORES from '@salesforce/label/c.MM_PROVEEDORES';
import MM_INGRESO_A_PUERTO from '@salesforce/label/c.MM_INGRESO_A_PUERTO';
import MM_EXTERNAL_ADRYAN from '@salesforce/label/c.MM_EXTERNAL_ADRYAN';
import MM_EXTERNAL_WORKDAY from '@salesforce/label/c.MM_EXTERNAL_WORKDAY';
import MM_EXTERNAL_WORKPLACE from '@salesforce/label/c.MM_EXTERNAL_WORKPLACE';
import MM_EXTERNAL_CONSULTAS from '@salesforce/label/c.MM_EXTERNAL_CONSULTAS';
import MM_PROCEDIMIENTO_DE_QEJAS_Y_RECLAMOS from '@salesforce/label/c.MM_PROCEDIMIENTO_DE_QEJAS_Y_RECLAMOS';
import MM_DANOS_A_CONOCER_TU_EMPRESA from '@salesforce/label/c.MM_DANOS_A_CONOCER_TU_EMPRESA';
import MM_CONOCENOS_MENU_LABEL from '@salesforce/label/c.MM_CONOCENOS_MENU_LABEL';
import MM_MINERIA_VERDE_MENU_LABEL from '@salesforce/label/c.MM_MINERIA_VERDE_MENU_LABEL';
import MM_SOSTENIBILIDAD_MENU_LABEL from '@salesforce/label/c.MM_SOSTENIBILIDAD_MENU_LABEL';
import MM_SEGURIDAD_MENU_LABEL from '@salesforce/label/c.MM_SEGURIDAD_MENU_LABEL';
import MM_SALUD_MENU_LABEL from '@salesforce/label/c.MM_SALUD_MENU_LABEL';
import MM_GESTION_AMBIENTAL_MENU_LABEL from '@salesforce/label/c.MM_GESTION_AMBIENTAL_MENU_LABEL';
import MM_POLITICAS_CORPORATIVAS_MENU_LABEL from '@salesforce/label/c.MM_POLITICAS_CORPORATIVAS_MENU_LABEL';
import MM_NOTICIAS_Y_PUBLICACIONES_MENU_LABEL from '@salesforce/label/c.MM_NOTICIAS_Y_PUBLICACIONES_MENU_LABEL';
import MM_CONTACTENOS_MENU_LABEL from '@salesforce/label/c.MM_CONTACTENOS_MENU_LABEL';
import MM_NOSOTROS_MENU_LABEL from '@salesforce/label/c.MM_NOSOTROS_MENU_LABEL';
import MM_NUESTROS_ACCIONISTAS_MENU_LABEL from '@salesforce/label/c.MM_NUESTROS_ACCIONISTAS_MENU_LABEL';
import MM_NUESTROS_LIDERES_MENU_LABEL from '@salesforce/label/c.MM_NUESTROS_LIDERES_MENU_LABEL';
import MM_PREMIOS_Y_RECONOCIMIENTOS_MENU_LABEL from '@salesforce/label/c.MM_PREMIOS_Y_RECONOCIMIENTOS_MENU_LABEL';
import MM_PROCESO_PRODUCTIVO_MENU_LABEL from '@salesforce/label/c.MM_PROCESO_PRODUCTIVO_MENU_LABEL';
import MM_HACEMOS_MINERIA_VERDE_MENU_LABEL from '@salesforce/label/c.MM_HACEMOS_MINERIA_VERDE_MENU_LABEL';
import MM_NUESTRO_PRODUCTO_MENU_LABEL from '@salesforce/label/c.MM_NUESTRO_PRODUCTO_MENU_LABEL';
import MM_GESTION_SOCIAL_MENU_LABEL from '@salesforce/label/c.MM_GESTION_SOCIAL_MENU_LABEL';
import MM_COMPROMISOS_CONTRACTUALES_MENU_LABEL from '@salesforce/label/c.MM_COMPROMISOS_CONTRACTUALES_MENU_LABEL';
import MM_PROGRAMAS_SOCIALES_MENU_LABEL from '@salesforce/label/c.MM_PROGRAMAS_SOCIALES_MENU_LABEL';
import MM_PROVEEDORES_Y_CONTRATISTAS_LOCALES_MENU_LABEL from '@salesforce/label/c.MM_PROVEEDORES_Y_CONTRATISTAS_LOCALES_MENU_LABEL';
import MM_SISTEMA_INTEGRAL_DE_GESTION_MENU_LABEL from '@salesforce/label/c.MM_SISTEMA_INTEGRAL_DE_GESTION_MENU_LABEL';
import MM_9_REGLAS_PARA_SALVAGUARDAR_VIDAS_MENU_LABEL from '@salesforce/label/c.MM_9_REGLAS_PARA_SALVAGUARDAR_VIDAS_MENU_LABEL';
import MM_HERRAMIENTAS_DE_GESTION_MENU_LABEL from '@salesforce/label/c.MM_HERRAMIENTAS_DE_GESTION_MENU_LABEL';
import MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS_MENU_LABEL from '@salesforce/label/c.MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS_MENU_LABEL';
import MM_PROGRAMA_DE_MONITOREO_AMBIENTAL_MENU_LABEL from '@salesforce/label/c.MM_PROGRAMA_DE_MONITOREO_AMBIENTAL_MENU_LABEL';
import MM_PLAN_DE_CIERRE_DE_MINA_MENU_LABEL from '@salesforce/label/c.MM_PLAN_DE_CIERRE_DE_MINA_MENU_LABEL';
import MM_POLITICA_SIG_Y_POLITICA_SSMA_MENU_LABEL from '@salesforce/label/c.MM_POLITICA_SIG_Y_POLITICA_SSMA_MENU_LABEL';
import MM_ETICA_Y_CUMPLIMIENTO_MENU_LABEL from '@salesforce/label/c.MM_ETICA_Y_CUMPLIMIENTO_MENU_LABEL';
import MM_PREVENCION_DE_LA_DISCRIMINACION_ACOSO_Y_LAS_REPRESALIAS_MENU_LABEL from '@salesforce/label/c.MM_PREVENCION_DE_LA_DISCRIMINACION_ACOSO_Y_LAS_REPRESALIAS_MENU_LABEL';
import MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR_MENU_LABEL from '@salesforce/label/c.MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR_MENU_LABEL';
import MM_DIVERSIDAD_E_INCLUSION_MENU_LABEL from '@salesforce/label/c.MM_DIVERSIDAD_E_INCLUSION_MENU_LABEL';
import MM_NOTAS_DE_PRENSA_MENU_LABEL from '@salesforce/label/c.MM_NOTAS_DE_PRENSA_MENU_LABEL';
import MM_RESENAS_INSTITUCIONALES_MENU_LABEL from '@salesforce/label/c.MM_RESENAS_INSTITUCIONALES_MENU_LABEL';
import MM_BOLETINES_MENU_LABEL from '@salesforce/label/c.MM_BOLETINES_MENU_LABEL';
import MM_OTRAS_PUBLICACIONES_MENU_LABEL from '@salesforce/label/c.MM_OTRAS_PUBLICACIONES_MENU_LABEL';
import MM_CONSULTAS_MENU_LABEL from '@salesforce/label/c.MM_CONSULTAS_MENU_LABEL';
import MM_PROCEDIMIENTO_DE_QUEJAS_Y_RECLAMOS_MENU_LABEL from '@salesforce/label/c.MM_PROCEDIMIENTO_DE_QUEJAS_Y_RECLAMOS_MENU_LABEL';







const LABELS = {
    MM_BASEURL,
    MM_CONOCENOS_NOSOTROS,
    MM_CONOCENOS_ACCIONISTAS,
    MM_CONOCENOS_LIDERES,
    MM_CONOCENOS_PREMIOS,
    MM_PROCESO_PRODUCTIVO,
    MM_HACEMOS_MINERIA_VERDE,
    MM_NUESTRO_PRODUCTO,
    MM_GESTION_SOCIAL,
    MM_COMPROMISOS_CONTRACTUALES,
    MM_PROGRAMAS_SOCIALES,
    MM_PROVEDORES_CONTRATISTAS,
    MM_SEGURIDAD,
    MM_SISTEMA_INTEGRAL_DE_GESTION,
    MM_9REGLAS_PARA_SALVAGUARDAR_VIDAS,
    MM_HERRAMIENTAS_DE_GESTION,
    MM_SALUD,
    MM_GESTION_AMBIENTAL,
    MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS,
    MM_PROGRAMA_DE_MONITOREO_AMBIENTAL,
    MM_PLAN_DE_CIERRE_DE_MINA,
    MM_POLITICA_SIG_Y_POLITICA_SSMA,
    MM_ETICA_Y_CUMPLIMIENTO,
    MM_PREVENCION_DE_LA_DISCRIMINACION,
    MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR,
    MM_DIVERSIDAD_E_INCLUSION,
    MM_NOTAS_DE_PRENSA,
    MM_RESENAS_INSTITUCIONALES,
    MM_BOLETINES,
    MM_OTRAS_PUBLICACIONES,
    MM_REGISTRA_TU_CONSULTA,
    MM_PREGUNTAS_FREQUENTES,
    MM_TRABAJA_CON_NOSOTROS,
    MM_PROVEEDORES,
    MM_INGRESO_A_PUERTO,
    MM_EXTERNAL_ADRYAN,
    MM_EXTERNAL_WORKDAY,
    MM_EXTERNAL_WORKPLACE,
    MM_EXTERNAL_CONSULTAS,
    MM_PROCEDIMIENTO_DE_QEJAS_Y_RECLAMOS,
    MM_DANOS_A_CONOCER_TU_EMPRESA,
    MM_CONOCENOS_MENU_LABEL,
    MM_MINERIA_VERDE_MENU_LABEL,
    MM_SOSTENIBILIDAD_MENU_LABEL,
    MM_SEGURIDAD_MENU_LABEL,
    MM_SALUD_MENU_LABEL,
    MM_GESTION_AMBIENTAL_MENU_LABEL,
    MM_POLITICAS_CORPORATIVAS_MENU_LABEL,
    MM_NOTICIAS_Y_PUBLICACIONES_MENU_LABEL,
    MM_CONTACTENOS_MENU_LABEL,
    MM_NOSOTROS_MENU_LABEL,
    MM_NUESTROS_ACCIONISTAS_MENU_LABEL,
    MM_NUESTROS_LIDERES_MENU_LABEL,
    MM_PREMIOS_Y_RECONOCIMIENTOS_MENU_LABEL,
    MM_PROCESO_PRODUCTIVO_MENU_LABEL,
    MM_HACEMOS_MINERIA_VERDE_MENU_LABEL,
    MM_NUESTRO_PRODUCTO_MENU_LABEL,
    MM_GESTION_SOCIAL_MENU_LABEL,
    MM_COMPROMISOS_CONTRACTUALES_MENU_LABEL,
    MM_PROGRAMAS_SOCIALES_MENU_LABEL,
    MM_PROVEEDORES_Y_CONTRATISTAS_LOCALES_MENU_LABEL,
    MM_SISTEMA_INTEGRAL_DE_GESTION_MENU_LABEL,
    MM_9_REGLAS_PARA_SALVAGUARDAR_VIDAS_MENU_LABEL,
    MM_HERRAMIENTAS_DE_GESTION_MENU_LABEL,
    MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS_MENU_LABEL,
    MM_PROGRAMA_DE_MONITOREO_AMBIENTAL_MENU_LABEL,
    MM_PLAN_DE_CIERRE_DE_MINA_MENU_LABEL,
    MM_POLITICA_SIG_Y_POLITICA_SSMA_MENU_LABEL,
    MM_ETICA_Y_CUMPLIMIENTO_MENU_LABEL,
    MM_PREVENCION_DE_LA_DISCRIMINACION_ACOSO_Y_LAS_REPRESALIAS_MENU_LABEL,
    MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR_MENU_LABEL,
    MM_DIVERSIDAD_E_INCLUSION_MENU_LABEL,
    MM_NOTAS_DE_PRENSA_MENU_LABEL,
    MM_RESENAS_INSTITUCIONALES_MENU_LABEL,
    MM_BOLETINES_MENU_LABEL,
    MM_OTRAS_PUBLICACIONES_MENU_LABEL,
    MM_CONSULTAS_MENU_LABEL,
    MM_PROCEDIMIENTO_DE_QUEJAS_Y_RECLAMOS_MENU_LABEL
};

export default class MiskiMayoMenuStructure extends LightningElement {
    @track isOpen = false;

    icon = CARD_IMAGES + '/miskiMayoIcon.png';

    toggleMenu() {
        this.isOpen = !this.isOpen;
    }

    get menuClass() {
        return this.isOpen ? 'menu open' : 'menu';
    }

    // 1st level CLICK (mobile only: opens/closes the UL .submenu)
    handleTopClick(event) {
        if (window.innerWidth <= 768) {
            const li = event.target.closest('li.menu-item');
            if (li) {
                li.classList.toggle('open');
            }
        }
    }

    // 2nd level CLICK (mobile only: opens/closes the UL .sub-submenu)
    handleSubClick(event) {
        if (window.innerWidth <= 768) {
            const li = event.target.closest('li.submenu-item');
            if (!li) return;

            // if there are children (3rd level), acts as an accordion; otherwise, navigate
            const hasChildren = li.querySelector('.sub-submenu');
            if (hasChildren) {
                li.classList.toggle('open');
                event.stopPropagation();
                return;
            }
        }

        // (optional) navigation – leave commented if you are not using it yet
        
        const labelName = event.target.dataset.label;
        if (!labelName) return;
        const url = LABELS[labelName];
        const baseUrl = LABELS.MM_BASEURL;
        if (String(labelName).includes('EXTERNAL')) {
            window.open(url, '_blank');
        } else {
            window.location.href = baseUrl + url;
        }
        
    }

    // Click on the 3rd level item (if you want to activate navigation)
    handleClick(event) {
        
        const labelName = event.target.dataset.label;
        if (!labelName) return;
        const url = LABELS[labelName];
        const baseUrl = LABELS.MM_BASEURL;
        if (String(labelName).includes('EXTERNAL')) {
            window.open(url, '_blank');
        } else {
            window.location.href = baseUrl + url;
        }
        
    }

    get menuItems() {
        return [
            {
                name: LABELS.MM_CONOCENOS_MENU_LABEL,
                subItems: [
                    { name: LABELS.MM_NOSOTROS_MENU_LABEL, labelName: 'MM_CONOCENOS_NOSOTROS' },
                    { name: LABELS.MM_NUESTROS_ACCIONISTAS_MENU_LABEL, labelName: 'MM_CONOCENOS_ACCIONISTAS' },
                    { name: LABELS.MM_NUESTROS_LIDERES_MENU_LABEL, labelName: 'MM_CONOCENOS_LIDERES' },
                    { name: LABELS.MM_PREMIOS_Y_RECONOCIMIENTOS_MENU_LABEL, labelName: 'MM_CONOCENOS_PREMIOS' }
                ]
            },
            {
                name: LABELS.MM_MINERIA_VERDE_MENU_LABEL,
                subItems: [
                    { name: LABELS.MM_PROCESO_PRODUCTIVO_MENU_LABEL, labelName: 'MM_PROCESO_PRODUCTIVO' },
                    { name: LABELS.MM_HACEMOS_MINERIA_VERDE_MENU_LABEL, labelName: 'MM_HACEMOS_MINERIA_VERDE' },
                    { name: LABELS.MM_NUESTRO_PRODUCTO_MENU_LABEL, labelName: 'MM_NUESTRO_PRODUCTO' }
                ]
            },
            {
                name: LABELS.MM_SOSTENIBILIDAD_MENU_LABEL,
                subItems: [
                    {
                        name: LABELS.MM_GESTION_SOCIAL_MENU_LABEL,
                        labelName: 'MM_GESTION_SOCIAL',
                        subSubItems: [
                            { name: LABELS.MM_COMPROMISOS_CONTRACTUALES_MENU_LABEL, labelName: 'MM_COMPROMISOS_CONTRACTUALES' },
                            { name: LABELS.MM_PROGRAMAS_SOCIALES_MENU_LABEL, labelName: 'MM_PROGRAMAS_SOCIALES' },
                            { name: LABELS.MM_PROVEEDORES_Y_CONTRATISTAS_LOCALES_MENU_LABEL, labelName: 'MM_PROVEDORES_CONTRATISTAS' }
                        ]
                    },
                    {
                        name: LABELS.MM_SEGURIDAD_MENU_LABEL,
                        labelName: 'MM_SEGURIDAD',
                        subSubItems: [
                            { name: LABELS.MM_SISTEMA_INTEGRAL_DE_GESTION_MENU_LABEL, labelName: 'MM_SISTEMA_INTEGRAL_DE_GESTION' },
                            { name: LABELS.MM_9_REGLAS_PARA_SALVAGUARDAR_VIDAS_MENU_LABEL, labelName: 'MM_9REGLAS_PARA_SALVAGUARDAR_VIDAS' },
                            { name: LABELS.MM_HERRAMIENTAS_DE_GESTION_MENU_LABEL, labelName: 'MM_HERRAMIENTAS_DE_GESTION' }
                        ]
                    },
                    {
                        name: LABELS.MM_SALUD_MENU_LABEL,
                        labelName: 'MM_SALUD'
                    },
                    {
                        name: LABELS.MM_GESTION_AMBIENTAL_MENU_LABEL,
                        labelName: 'MM_GESTION_AMBIENTAL',
                        subSubItems: [
                            { name: LABELS.MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS_MENU_LABEL, labelName: 'MM_INSTRUMENTOS_DE_GESTION_AMBIENTAL_APROBADOS' },
                            { name: LABELS.MM_PROGRAMA_DE_MONITOREO_AMBIENTAL_MENU_LABEL, labelName: 'MM_PROGRAMA_DE_MONITOREO_AMBIENTAL' },
                            { name: LABELS.MM_PLAN_DE_CIERRE_DE_MINA_MENU_LABEL, labelName: 'MM_PLAN_DE_CIERRE_DE_MINA' }
                        ]
                    }
                ]
            },
            {
                name: LABELS.MM_POLITICAS_CORPORATIVAS_MENU_LABEL,
                subItems: [
                    { name: LABELS.MM_POLITICA_SIG_Y_POLITICA_SSMA_MENU_LABEL, labelName: 'MM_POLITICA_SIG_Y_POLITICA_SSMA'  },
                    { name: LABELS.MM_ETICA_Y_CUMPLIMIENTO_MENU_LABEL, labelName: 'MM_ETICA_Y_CUMPLIMIENTO'  },
                    { name: LABELS.MM_PREVENCION_DE_LA_DISCRIMINACION_ACOSO_Y_LAS_REPRESALIAS_MENU_LABEL, labelName: 'MM_PREVENCION_DE_LA_DISCRIMINACION'  },
                    { name: LABELS.MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR_MENU_LABEL, labelName: 'MM_CONDUCTA_Y_ETICA_DEL_PROVEEDOR'  },
                    { name: LABELS.MM_DIVERSIDAD_E_INCLUSION_MENU_LABEL, labelName: 'MM_DIVERSIDAD_E_INCLUSION'  }
                ]
            },
            {
                name: LABELS.MM_NOTICIAS_Y_PUBLICACIONES_MENU_LABEL,
                subItems: [
                    { name: LABELS.MM_NOTAS_DE_PRENSA_MENU_LABEL, labelName: 'MM_NOTAS_DE_PRENSA'  },
                    { name: LABELS.MM_RESENAS_INSTITUCIONALES_MENU_LABEL, labelName: 'MM_RESENAS_INSTITUCIONALES'  },
                    { name: LABELS.MM_BOLETINES_MENU_LABEL, labelName: 'MM_BOLETINES'  },
                    { name: LABELS.MM_OTRAS_PUBLICACIONES_MENU_LABEL, labelName: 'MM_OTRAS_PUBLICACIONES'  }
                ]
            },
            {
                name: LABELS.MM_CONTACTENOS_MENU_LABEL,
                subItems: [
                    { name: LABELS.MM_CONSULTAS_MENU_LABEL, labelName: 'MM_EXTERNAL_CONSULTAS'  },
                    { name: LABELS.MM_PROCEDIMIENTO_DE_QUEJAS_Y_RECLAMOS_MENU_LABEL, labelName: 'MM_PROCEDIMIENTO_DE_QEJAS_Y_RECLAMOS'  }
                ]
            }
        ];
    }
}