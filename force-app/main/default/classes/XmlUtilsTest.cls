@IsTest
private class XmlUtilsTest {

    @IsTest
    static void testJsonToXmlSimpleObject() {
        String jsonInput = '{"Person": {"Name": "John Doe", "Age": 30, "City": "New York"}}';
        String rootName = 'Root';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput, rootName);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Root>'), 'XML should contain Root element');
        System.assert(xmlOutput.contains('<Person>'), 'XML should contain Person element');
        System.assert(xmlOutput.contains('<Name>John Doe</Name>'), 'XML should contain Name element');
        System.assert(xmlOutput.contains('<Age>30</Age>'), 'XML should contain Age element');
        System.assert(xmlOutput.contains('<City>New York</City>'), 'XML should contain City element');
    }

    @IsTest
    static void testJsonToXmlWithInferredRoot() {
        String jsonInput = '{"Document": {"Id": "123", "Name": "Test Document"}}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Document>'), 'XML should contain Document root element');
        System.assert(xmlOutput.contains('<Id>123</Id>'), 'XML should contain Id element');
        System.assert(xmlOutput.contains('<Name>Test Document</Name>'), 'XML should contain Name element');
    }

    @IsTest
    static void testJsonToXmlWithNestedObject() {
        String jsonInput = '{"Order": {"Customer": {"Name": "Jane", "Email": "jane@example.com"}, "Total": 100}}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Order>'), 'XML should contain Order element');
        System.assert(xmlOutput.contains('<Customer>'), 'XML should contain Customer element');
        System.assert(xmlOutput.contains('<Name>Jane</Name>'), 'XML should contain Name element');
        System.assert(xmlOutput.contains('<Email>jane@example.com</Email>'), 'XML should contain Email element');
        System.assert(xmlOutput.contains('<Total>100</Total>'), 'XML should contain Total element');
    }

    @IsTest
    static void testJsonToXmlWithArray() {
        String jsonInput = '{"Products": [{"Name": "Product1", "Price": 10}, {"Name": "Product2", "Price": 20}]}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Products>'), 'XML should contain Products element');
        System.assert(xmlOutput.contains('<Product>'), 'XML should contain Product elements');
        System.assert(xmlOutput.contains('<Name>Product1</Name>'), 'XML should contain first product name');
        System.assert(xmlOutput.contains('<Name>Product2</Name>'), 'XML should contain second product name');
        System.assert(xmlOutput.contains('<Price>10</Price>'), 'XML should contain first product price');
        System.assert(xmlOutput.contains('<Price>20</Price>'), 'XML should contain second product price');
    }

    @IsTest
    static void testJsonToXmlWithPrimitiveArray() {
        String jsonInput = '{"Numbers": [1, 2, 3, 4, 5]}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Numbers>'), 'XML should contain Numbers element');
        System.assert(xmlOutput.contains('<Number>1</Number>'), 'XML should contain first number');
        System.assert(xmlOutput.contains('<Number>5</Number>'), 'XML should contain last number');
    }

    @IsTest
    static void testJsonToXmlWithNullValue() {
        String jsonInput = '{"Data": {"Field1": "Value1", "Field2": null}}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Data>'), 'XML should contain Data element');
        System.assert(xmlOutput.contains('<Field1>Value1</Field1>'), 'XML should contain Field1');
        System.assert(xmlOutput.contains('<Field2></Field2>'), 'XML should contain empty Field2 element');
    }

    @IsTest
    static void testJsonToXmlBlankInput() {
        String jsonInput = '';

        Test.startTest();
        try {
            XmlUtils.jsonToXml(jsonInput, 'Root');
            System.assert(false, 'Should throw CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('blank or null'), 'Should throw blank or null exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testJsonToXmlInvalidJson() {
        String jsonInput = '{invalid json}';

        Test.startTest();
        try {
            XmlUtils.jsonToXml(jsonInput, 'Root');
            System.assert(false, 'Should throw CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('invalid'), 'Should throw invalid JSON exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMapToXml() {
        Map<String, Object> dataMap = new Map<String, Object>{
            'Name' => 'Test',
            'Value' => 123,
            'Active' => true
        };

        Test.startTest();
        String xmlOutput = XmlUtils.mapToXml(dataMap, 'Data');
        Test.stopTest();

        System.assert(xmlOutput.contains('<Data>'), 'XML should contain Data root element');
        System.assert(xmlOutput.contains('<Name>Test</Name>'), 'XML should contain Name element');
        System.assert(xmlOutput.contains('<Value>123</Value>'), 'XML should contain Value element');
        System.assert(xmlOutput.contains('<Active>true</Active>'), 'XML should contain Active element');
    }

    @IsTest
    static void testMapToXmlInferredRoot() {
        Map<String, Object> dataMap = new Map<String, Object>{
            'Document' => new Map<String, Object>{
                'Id' => '1234',
                'Title' => 'Test Document'
            }
        };

        Test.startTest();
        String xmlOutput = XmlUtils.mapToXml(dataMap);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Document>'), 'XML should contain Document element');
        System.assert(xmlOutput.contains('<Id>1234</Id>'), 'XML should contain Id element');
        System.assert(xmlOutput.contains('<Title>Test Document</Title>'), 'XML should contain Title element');
    }

    @IsTest
    static void testMapToXmlNestedMap() {
        Map<String, Object> dataMap = new Map<String, Object>{
            'Parent' => new Map<String, Object>{
                'Child' => new Map<String, Object>{
                    'GrandChild' => 'Value'
                }
            }
        };

        Test.startTest();
        String xmlOutput = XmlUtils.mapToXml(dataMap, 'Root');
        Test.stopTest();

        System.assert(xmlOutput.contains('<Root>'), 'XML should contain Root element');
        System.assert(xmlOutput.contains('<Parent>'), 'XML should contain Parent element');
        System.assert(xmlOutput.contains('<Child>'), 'XML should contain Child element');
        System.assert(xmlOutput.contains('<GrandChild>Value</GrandChild>'), 'XML should contain GrandChild element');
    }

    @IsTest
    static void testMapToXmlWithList() {
        List<Object> items = new List<Object>{
            new Map<String, Object>{ 'Name' => 'Item1' },
            new Map<String, Object>{ 'Name' => 'Item2' }
        };
        Map<String, Object> dataMap = new Map<String, Object>{ 'Items' => items };

        Test.startTest();
        String xmlOutput = XmlUtils.mapToXml(dataMap, 'Root');
        Test.stopTest();

        System.assert(xmlOutput.contains('<Root>'), 'XML should contain Root element');
        System.assert(xmlOutput.contains('<Items>'), 'XML should contain Items element');
        System.assert(xmlOutput.contains('<Item>'), 'XML should contain Item elements');
        System.assert(xmlOutput.contains('<Name>Item1</Name>'), 'XML should contain first item name');
        System.assert(xmlOutput.contains('<Name>Item2</Name>'), 'XML should contain second item name');
    }

    @IsTest
    static void testMapToXmlEmptyMap() {
        Map<String, Object> dataMap = new Map<String, Object>();

        Test.startTest();
        try {
            XmlUtils.mapToXml(dataMap, 'Root');
            System.assert(false, 'Should throw CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Should throw null or empty exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMapToXmlNullMap() {
        Map<String, Object> dataMap = null;

        Test.startTest();
        try {
            XmlUtils.mapToXml(dataMap, 'Root');
            System.assert(false, 'Should throw CustomException');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Should throw null or empty exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testJsonToXmlSingleKeyPrimitive() {
        String jsonInput = '{"Message": "Hello World"}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Message>Hello World</Message>'), 'XML should contain Message with text content');
    }

    @IsTest
    static void testJsonToXmlMultipleKeys() {
        String jsonInput = '{"Key1": "Value1", "Key2": "Value2"}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        // Should fall back to generic Root element
        System.assert(xmlOutput.contains('<Root>'), 'XML should contain Root element');
        System.assert(xmlOutput.contains('<Key1>Value1</Key1>'), 'XML should contain Key1');
        System.assert(xmlOutput.contains('<Key2>Value2</Key2>'), 'XML should contain Key2');
    }

    @IsTest
    static void testMapToXmlSpecialCharacters() {
        Map<String, Object> dataMap = new Map<String, Object>{
            'Field-With-Dashes' => 'Value1',
            'Field_With_Underscores' => 'Value2',
            'Field@With@Special' => 'Value3'
        };

        Test.startTest();
        String xmlOutput = XmlUtils.mapToXml(dataMap, 'Root');
        Test.stopTest();

        System.assert(xmlOutput.contains('<Root>'), 'XML should contain Root element');
        // Special characters are sanitized
        System.assert(xmlOutput.contains('<FieldWithDashes>') || xmlOutput.contains('<Field-With-Dashes>'), 'Should handle dashes');
        System.assert(xmlOutput.contains('<Field_With_Underscores>'), 'Should handle underscores');
    }

    @IsTest
    static void testJsonToXmlComplexNested() {
        String jsonInput = '{"Order": {"Customer": {"Name": "John", "Address": {"Street": "Main St", "City": "NYC"}}, "Items": [{"Product": "A", "Qty": 2}, {"Product": "B", "Qty": 3}]}}';

        Test.startTest();
        String xmlOutput = XmlUtils.jsonToXml(jsonInput);
        Test.stopTest();

        System.assert(xmlOutput.contains('<Order>'), 'XML should contain Order element');
        System.assert(xmlOutput.contains('<Customer>'), 'XML should contain Customer element');
        System.assert(xmlOutput.contains('<Address>'), 'XML should contain Address element');
        System.assert(xmlOutput.contains('<Street>Main St</Street>'), 'XML should contain Street element');
        System.assert(xmlOutput.contains('<Items>'), 'XML should contain Items element');
        System.assert(xmlOutput.contains('<Product>A</Product>'), 'XML should contain first product');
        System.assert(xmlOutput.contains('<Qty>2</Qty>'), 'XML should contain first quantity');
    }
}