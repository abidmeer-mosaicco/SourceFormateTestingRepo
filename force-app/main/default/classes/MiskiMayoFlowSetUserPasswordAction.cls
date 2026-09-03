public without sharing class MiskiMayoFlowSetUserPasswordAction {

    public class Input {
        @InvocableVariable(required=true)
        public Id userId;

        @InvocableVariable(required=true)
        public String password;
    }

    @InvocableMethod(
        label='Set User Password'
        description='Sets a Salesforce user password using System.setPassword(userId, password).'
    )
    public static void setPassword(List<Input> inputs) {

        System.debug('List<Input> inputs '+inputs);
			for (Input i : inputs) {
            System.setPassword(i.userId, i.password);
        }
    }
}