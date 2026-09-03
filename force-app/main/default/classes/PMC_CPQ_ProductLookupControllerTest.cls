@isTest
private class PMC_CPQ_ProductLookupControllerTest {

    @isTest
    static void testFindProductsWithValidKey() {
        // Cria um produto com os dados que serão usados pela fórmula
        Product2 p = new Product2(
            Name = 'Produto A',
            ProductCode = 'P001',
            PMC_CPQ_SAPProductCode__c = 'SAP123',
            IsActive = true
        );
        insert p;

        // A fórmula PMC_CPQ_Product_Code_Name__c será: "SAP123 - Produto A"
        Test.startTest();
        List<Product2> result = PMC_CPQ_ProductLookupController.findProducts('SAP123');
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deveria retornar o produto correspondente');
        System.assertEquals(p.Id, result[0].Id, 'O ID deve coincidir');
    }

    @isTest
    static void testFindProductsWithShortKey() {
        Test.startTest();
        List<Product2> result = PMC_CPQ_ProductLookupController.findProducts('S'); // Apenas 1 caractere
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Não deve retornar resultados com menos de 2 caracteres');
    }

    @isTest
    static void testFindProductsWithNullKey() {
        Test.startTest();
        List<Product2> result = PMC_CPQ_ProductLookupController.findProducts(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Não deve retornar resultados para valor nulo');
    }

    @isTest
    static void testGetProductById() {
        Product2 p = new Product2(
            Name = 'Produto B',
            ProductCode = 'P002',
            PMC_CPQ_SAPProductCode__c = 'SAP456',
            IsActive = true
        );
        insert p;

        Test.startTest();
        Product2 result = PMC_CPQ_ProductLookupController.getProductById(p.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'O produto deve ser retornado');
        System.assertEquals(p.Id, result.Id, 'O ID retornado deve ser igual ao inserido');
    }

    @isTest
    static void testGetProductByIdWithNullId() {
        Test.startTest();
        Product2 result = PMC_CPQ_ProductLookupController.getProductById(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Deve retornar null quando o ID é nulo');
    }
}