/**
* @description : Test class for the contract item selection used by Contract Details and Request to Deliver
* @userStory   : GMDP-2743
**/
@isTest
public with sharing class PMC_DH_ContractItemSelectionTest {
    private static final Id CONTRACT_ID = Id.valueOf('800000000000001');
    private static final Id ORIGINAL_LINE_ONE_ID = Id.valueOf('a3O000000000001');
    private static final Id REVERSAL_LINE_ONE_ID = Id.valueOf('a3O000000000002');
    private static final Id ORIGINAL_LINE_TWO_ID = Id.valueOf('a3O000000000003');
    private static final Id ADDED_LINE_TWO_ID = Id.valueOf('a3O000000000004');
    private static final Datetime ORIGINAL_CREATED_DATE = Datetime.newInstanceGmt(2026, 7, 14, 14, 6, 31);
    private static final Datetime AMENDMENT_CREATED_DATE = Datetime.newInstanceGmt(2026, 7, 17, 18, 18, 6);

    @isTest
    static void amendmentReversalIsNeverSelectedAsContractItem(){
        Contract objContract = buildContract(new List<Object>{
            buildSubscription(REVERSAL_LINE_ONE_ID, -500, AMENDMENT_CREATED_DATE, ORIGINAL_LINE_ONE_ID, null),
            buildSubscription(ADDED_LINE_TWO_ID, 500, AMENDMENT_CREATED_DATE, null, null),
            buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, ORIGINAL_CREATED_DATE, null, null),
            buildSubscription(ORIGINAL_LINE_TWO_ID, 1000, ORIGINAL_CREATED_DATE, null, null)
        });

        Test.startTest();
        Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{objContract});
        Test.stopTest();

        Set<Id> setSelectedSubscriptionIds = new Set<Id>(mapUniqueSubscriptionIds.values());
        System.assert(!setSelectedSubscriptionIds.contains(REVERSAL_LINE_ONE_ID), 'A linha de estorno do amendment nao pode virar item de contrato');
        System.assert(setSelectedSubscriptionIds.contains(ORIGINAL_LINE_ONE_ID), 'A linha original deve substituir o estorno no mesmo item de contrato');
        System.assert(setSelectedSubscriptionIds.contains(ADDED_LINE_TWO_ID), 'O item incluido pelo amendment deve ficar disponivel');
        System.assertEquals(3, setSelectedSubscriptionIds.size(), 'Cada linha de contrato deve gerar exatamente um item');
    }

    @isTest
    static void latestSubscriptionWinsForSameContractLineNumber(){
        Contract objContract = buildContract(new List<Object>{
            buildSubscription(ADDED_LINE_TWO_ID, 500, AMENDMENT_CREATED_DATE, null, '1'),
            buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, ORIGINAL_CREATED_DATE, null, '1')
        });

        Test.startTest();
        Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{objContract});
        Test.stopTest();

        System.assertEquals(1, mapUniqueSubscriptionIds.size(), 'O numero de linha do contrato deve agrupar as subscriptions');
        System.assertEquals(ADDED_LINE_TWO_ID, mapUniqueSubscriptionIds.values()[0], 'A subscription mais recente deve representar a linha de contrato');
    }

    @isTest
    static void identicalCreatedDateIsResolvedDeterministically(){
        Contract objContract = buildContract(new List<Object>{
            buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, AMENDMENT_CREATED_DATE, null, '1'),
            buildSubscription(ADDED_LINE_TWO_ID, 500, AMENDMENT_CREATED_DATE, null, '1')
        });
        Contract objContractReversedOrder = buildContract(new List<Object>{
            buildSubscription(ADDED_LINE_TWO_ID, 500, AMENDMENT_CREATED_DATE, null, '1'),
            buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, AMENDMENT_CREATED_DATE, null, '1')
        });

        Test.startTest();
        Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{objContract});
        Map<String, Id> mapReversedOrderSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{objContractReversedOrder});
        Test.stopTest();

        System.assertEquals(ADDED_LINE_TWO_ID, mapUniqueSubscriptionIds.values()[0], 'O empate de CreatedDate deve ser resolvido pelo maior Id');
        System.assertEquals(mapUniqueSubscriptionIds.values()[0], mapReversedOrderSubscriptionIds.values()[0], 'A ordem retornada pela query nao pode alterar o item escolhido');
    }

    @isTest
    static void contractLinesWithoutNumberAreNotCollapsed(){
        Contract objContract = buildContract(new List<Object>{
            buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, ORIGINAL_CREATED_DATE, null, null),
            buildSubscription(ORIGINAL_LINE_TWO_ID, 1000, ORIGINAL_CREATED_DATE, null, null)
        });

        Test.startTest();
        Map<String, Id> mapUniqueSubscriptionIds = PMC_DH_ContractManagementController.getMapOfSubscriptionIds(new List<Contract>{objContract});
        Test.stopTest();

        System.assertEquals(2, mapUniqueSubscriptionIds.size(), 'Linhas de contrato distintas sem numero de linha nao podem colapsar numa unica chave');
    }

    @isTest
    static void amendmentWrapperResolvesContractItemWithSharedKey(){
        SBQQ__Subscription__c objSubscription = (SBQQ__Subscription__c) JSON.deserialize(
            JSON.serialize(buildSubscription(ORIGINAL_LINE_ONE_ID, 1000, ORIGINAL_CREATED_DATE, null, '1')), SBQQ__Subscription__c.class);
        SBQQ__QuoteLine__c objQuoteLine = (SBQQ__QuoteLine__c) JSON.deserialize(JSON.serialize(buildQuoteLine('1')), SBQQ__QuoteLine__c.class);
        Map<String, Id> mapUniqueSubscriptionIds = new Map<String, Id>{
            PMC_DH_ContractManagementController.buildSubscriptionKey(CONTRACT_ID, objSubscription, null) => ORIGINAL_LINE_ONE_ID
        };

        Test.startTest();
        PMC_DH_RequestForQuoteWrapper.ContractItemsWrapper objContractItem = PMC_DH_ContractAmendmentController.getQuoteSubscriptionDetailsMap(
            objQuoteLine, objSubscription, mapUniqueSubscriptionIds, new Map<Id, SBQQ__Subscription__c>{objSubscription.Id => objSubscription});
        Test.stopTest();

        System.assertEquals(ORIGINAL_LINE_ONE_ID, objContractItem.strContractItemId, 'A tela de amendment deve resolver o item pela mesma chave do dedupe');
    }

    private static Contract buildContract(List<Object> lstSubscriptions){
        Map<String, Object> mapContract = new Map<String, Object>{
            'attributes' => new Map<String, Object>{'type' => 'Contract'},
            'Id' => CONTRACT_ID,
            'SBQQ__Subscriptions__r' => new Map<String, Object>{
                'totalSize' => lstSubscriptions.size(),
                'done' => true,
                'records' => lstSubscriptions
            }
        };
        return (Contract) JSON.deserialize(JSON.serialize(mapContract), Contract.class);
    }

    private static Map<String, Object> buildSubscription(Id subscriptionId, Decimal quantity, Datetime createdDate, Id revisedSubscriptionId, String contractLineNumber){
        return new Map<String, Object>{
            'attributes' => new Map<String, Object>{'type' => 'SBQQ__Subscription__c'},
            'Id' => subscriptionId,
            'CreatedDate' => createdDate,
            'SBQQ__Quantity__c' => quantity,
            'SBQQ__contract__c' => CONTRACT_ID,
            'SBQQ__RevisedSubscription__c' => revisedSubscriptionId,
            'PMC_CPQ_TotalOrderedQuantity__c' => 0,
            'PMC_CPQ_TotalAvailableQuantity__c' => quantity,
            'SBQQ__QuoteLine__r' => buildQuoteLine(contractLineNumber)
        };
    }

    private static Map<String, Object> buildQuoteLine(String contractLineNumber){
        return new Map<String, Object>{
            'attributes' => new Map<String, Object>{'type' => 'SBQQ__QuoteLine__c'},
            'Id' => Id.valueOf('a38000000000001'),
            'SBQQ__Number__c' => 1,
            'SBQQ__Quantity__c' => 1000,
            'PMC_CLM_QuoteLineNumber__c' => contractLineNumber,
            'PMC_CPQ_ShipTo__c' => Id.valueOf('001000000000001'),
            'PMC_CPQ_ShipTo__r' => new Map<String, Object>{
                'attributes' => new Map<String, Object>{'type' => 'Account'},
                'Id' => Id.valueOf('001000000000001'),
                'Name' => 'Ship To Teste',
                'ShippingStreet' => 'Rua Teste',
                'ShippingCity' => 'Uberaba',
                'ShippingState' => 'MG',
                'ShippingPostalCode' => '38000000'
            }
        };
    }
}