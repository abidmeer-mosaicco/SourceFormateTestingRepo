import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import login from '@salesforce/apex/MiskMayoCommunityAuthController.login';

export default class MiskMayocustomCommunityLogin extends NavigationMixin(LightningElement) {

    @api usernameLabel = 'Correo';
    @api passwordLabel = 'Contraseña';
    @api loginButtonLabel = 'INGRESA';
    @api selfRegisterLabel = 'REGÍSTRATE';
    @api forgotPasswordLabel = '¿Olvidaste tu contraseña?';
    @api resetPasswordButtonLabel = 'RESTABLECER CONTRASEÑA';

    @api minPasswordLength = 8;
    @api forgotPasswordUrl;
    @api selfRegisterUrl;
    @api logoUrl;

    username = '';
    password = '';
    errorMessage = '';
    isLoading = false;
    startUrl = '/';

    @wire(CurrentPageReference)
    getState(pageRef) {
        this.startUrl = pageRef?.state?.startURL || '/';
    }

    get isLoginDisabled() {
        return !this.username ||
               this.password.length < this.minPasswordLength ||
               this.isLoading;
    }

    handleUsernameChange(event) {
        this.username = event.target.value;
        this.errorMessage = '';
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
        this.errorMessage = '';
    }

    handleKeyUp(event) {
        if (event.key === 'Enter' && !this.isLoginDisabled) {
            this.handleLogin();
        }
    }

    async handleLogin() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            const result = await login({
                username: this.username,
                password: this.password,
                startUrl: this.startUrl
            });

            if (!result.success) {
                this.errorMessage = result.errorMessage;
                return;
            }

            window.location.assign(result.redirectUrl);
            /*this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: result.redirectUrl }
            });*/

        } catch (e) {
            this.errorMessage = 'No fue posible iniciar sesión.';
        } finally {
            this.isLoading = false;
        }
    }

    goToForgotPassword() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: this.forgotPasswordUrl }
        });
    }

    async goToSelfRegister() {
        const targetUrl = (this.selfRegisterURL || this.selfRegisterUrl || '').trim();
        if (!targetUrl) {
            return;
        }
        try {
            const url = await this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: targetUrl }
            });
        } catch (e) {
            console.error('Error in go to SelfRegister: '+e)
        }
    }
}