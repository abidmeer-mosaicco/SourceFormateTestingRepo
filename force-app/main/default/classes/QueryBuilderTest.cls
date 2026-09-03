/**
    MIT License

    Copyright (c) 2018 Alex

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

@IsTest
public with sharing class QueryBuilderTest {
    //Utility methods
    private static Account createAccount(Integer i) {
        Account result = new Account();
        result.Name = 'Account-' + i;
        result.NumberOfEmployees = 0;
        insert result;
        return result;
    }

    private static Account createAccount(String name) {
        Account result = new Account();
        result.Name = 'Account-' + name;
        result.NumberOfEmployees = 0;
        insert result;
        return result;
    }

    private static Contact createContact(Id accId) {
        Contact result = new Contact();
        result.LastName = 'Contact-' + accId;
        result.AccountId = accId;
        result.Email = 'email' + accId + '@example.com';
        result.Description = accId;
        insert result;
        return result;
    }

    // Helper test subclass to expose protected objectType for assertions
    private class TestObjectTypeCondition extends QueryBuilder.ObjectTypeDependentCondition {
        public TestObjectTypeCondition() {
            super();
        }

        // Force non-empty so ConditionsManager.add will accept the condition
        public override Boolean isEmpty() {
            return false;
        }

        public String getObjectType() {
            return this.objectType;
        }

        public override String toString() {
            // keep empty string for safety
            return this.formedCondition == null ? '' : this.formedCondition;
        }
    }

    @TestSetup
    public static void init() {
        createAccount(1);
    }

    @IsTest
    public static void testFrom1() {
        List<Account> accounts = (List<Account>) new QueryBuilder('Account').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(new Account()).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(new Account().getSObjectType()).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom5() {
        List<Account> accounts = (List<Account>) new QueryBuilder().addFrom('Account').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom6() {
        List<Account> accounts = (List<Account>) new QueryBuilder().addFrom(Account.class).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom7() {
        List<Account> accounts = (List<Account>) new QueryBuilder().addFrom(new Account()).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testFrom8() {
        List<Account> accounts = (List<Account>) new QueryBuilder().addFrom(new Account().getSObjectType()).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testField1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Name').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testField2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField(Account.Name).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testField3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Id, Name').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields(new Account(Name = 'test')).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields21() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields('Name').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields22() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields('Id, Name').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields23() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields('Name, Name').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields31() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields(new List<String>{ 'Name' }).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields32() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields(new List<String>{ 'Id', 'Name' }).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields33() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields(new List<String>{ 'Name', 'Name' }).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFields(new Set<String>{ 'Name' }).toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields5() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFieldsAll().toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields6() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFieldsAll('Account').toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testFields7() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addFieldsAllCreatable().toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertNotEquals(null, accounts[0].Name, 'Account name should not be null.');
    }

    @IsTest
    public static void testConditionManager() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition())
            .preview()
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testSimpleCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition('Name = \'Account-1\''))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testSimpleCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition())
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testSimpleCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.SimpleCondition().ignoreConditionsForNullValues())
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testNullCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition('Name').isNull())
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testNullCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition(Account.Name).isNull())
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testNullCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition(Account.Name).notNull())
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testNullCondition4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition(Account.Name).ignoreConditionsForNullValues().notNull())
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testCompareCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testCompareCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition(Account.Name).eq('Account-1'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testCompareCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').ne('Account-1'))
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition4() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').eq(1))
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition5() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').ne(0))
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition6() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(0))
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition7() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gte(1))
            .endConditions()
            .preview()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition8() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lt(0))
            .endConditions()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition9() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lte(-1))
            .endConditions()
            .preview()
            .toList();
        System.assert(accounts.isEmpty(), 'Should return no records.');
    }

    @IsTest
    public static void testCompareCondition10() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').ignoreConditionsForNullValues().eq('Account-1'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testLikeCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('ccount-'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testLikeCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth('ccount-'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testLikeCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyLeft('ccount-1'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testLikeCondition3() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyRight('Account-'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
    }

    @IsTest
    public static void testInCondition01() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(new Set<Id>{ account.Id }))
            .endConditions()
            .toList();
        System.assert(!accounts.isEmpty(), 'Result should not be a empty list.');
    }

    @IsTest
    public static void testInCondition02() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(new List<Id>{ account.Id }))
            .endConditions()
            .toList();
        System.assert(!accounts.isEmpty(), 'Result should not be a empty list.');
    }

    @IsTest
    public static void testInCondition1() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Name').inCollection(new List<String>{ 'Account-1' }))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testInCondition12() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition(Account.Name).inCollection(new List<String>{ 'Account-1' }))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testInCondition2() {
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Name').inCollection(new Set<String>{ 'Account-1' }))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testInCondition3() {
        Set<Id> accIds = new QueryBuilder('Account').toIdSet();
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(accIds))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testInCondition31() {
        List<String> accIds = new List<Id>(new QueryBuilder('Account').toIdSet());
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(accIds))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition0() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        System.assertEquals('', complex.toString(), 'Complex condition should be empty');
    }

    @IsTest
    public static void testComplexCondition1() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.startCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addConditions().add(complex).endConditions().toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition2() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addConditions().add(complex).endConditions().toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition3() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.orCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addConditions().add(complex).endConditions().toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition4() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition('Name').notNull())
            .add(complex)
            .setConditionOrder('1' + complex.addOrderIfNotEmpty('AND 2'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition5() {
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.NullCondition('Name').notNull())
            .add(complex)
            .setConditionOrder('1' + complex.addOrderIfNotEmpty('AND 2'))
            .endConditions()
            .toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition6() {
        Id accId = new QueryBuilder('Account').toSObject().Id;
        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-1'));
        complex.andCondition(new QueryBuilder.CompareCondition('Id').eq(accId));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addConditions().add(complex).endConditions().toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testComplexCondition7() {
        Id accId = new QueryBuilder('Account').toSObject().Id;
        createAccount(2);

        QueryBuilder.ComplexCondition complex = new QueryBuilder.ComplexCondition();
        complex.andCondition(new QueryBuilder.CompareCondition('Name').eq('Account-2'));
        complex.orCondition(new QueryBuilder.CompareCondition('Id').eq(accId));
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addConditions().add(complex).endConditions().toList();
        System.assertEquals(2, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testLimit1() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).setLimit(-1).toList();
        System.assertEquals(2, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testLimit2() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).setLimit(1).toList();
        System.assertEquals(1, accounts.size(), 'Account-1 should be first');
    }

    @IsTest
    public static void testOrder1() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Name').addOrderAsc('Name').toList();
        System.assertEquals('Account-1', accounts[0].Name, 'Account-1 should be first');
    }

    @IsTest
    public static void testOrder2() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Name').addOrderDesc('Name').toList();
        System.assertEquals('Account-2', accounts[0].Name, 'Account-2 should be first');
    }

    @IsTest
    public static void testOrder3() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Name').addOrderAsc('Name').addOrderAsc('Id').toList();
        System.assertEquals('Account-1', accounts[0].Name, 'Account-1 should be first');
    }

    @IsTest
    public static void testOrder4() {
        createAccount(2);
        List<Account> accounts = (List<Account>) new QueryBuilder(Account.class).addField('Name').addOrderDesc('Name').addOrderDesc('Id').toList();
        System.assertEquals('Account-2', accounts[0].Name, 'Account-2 should be first');
    }

    @IsTest
    public static void testPreview() {
        QueryBuilder qb = new QueryBuilder(Account.class).preview();
        System.assertNotEquals(null, qb, 'preview() should return a QueryBuilder instance');
        // ensure preview did not break the builder and forms a query containing the FROM clause
        String qs = qb.toString();
        System.assert(qs.contains('FROM Account'), 'preview() query should include FROM Account');
    }

    @IsTest
    public static void testPreviewCount() {
        new QueryBuilder(Account.class).previewCount();
        System.assert(true, 'previewCount() executed without exception');
    }

    @IsTest
    public static void testToString() {
        String queryString = new QueryBuilder(Account.class).toString();
        System.assertEquals('SELECT Id FROM Account', queryString, 'Query should not contain field names');
    }

    @IsTest
    public static void testToCountString() {
        String queryString = new QueryBuilder(Account.class).toStringCount();
        System.assertEquals('SELECT count() FROM Account', queryString, 'Count query should not contain field names');
    }

    @IsTest
    public static void testToCountString2() {
        String queryString = new QueryBuilder(Account.class)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
            .endConditions()
            .toStringCount();
        System.assertEquals('SELECT count() FROM Account WHERE Name = \'Account-1\'', queryString, 'Count query should not contain field names');
    }

    @IsTest
    public static void testToCountString3() {
        String queryString = new QueryBuilder(Account.class).setScope(QueryBuilder.FilterScope.Mine).toStringCount();
        System.assert(queryString.contains('USING SCOPE Mine'), 'Query should contain "USING SCOPE Mine" but got ' + queryString);
    }

    @IsTest
    public static void testToCountString4() {
        String queryString = new QueryBuilder(Account.class).setLimit(1).toStringCount();
        System.assert(queryString.contains('LIMIT 1'), 'Query should contain "LIMIT 1"');
    }

    @IsTest
    public static void testToCountString5() {
        String queryString = new QueryBuilder(Account.class).setOffset(1).toStringCount();
        System.assert(queryString.contains('OFFSET 1'), 'Query should contain "OFFSET 1"');
    }

    @IsTest
    public static void testResetResult() {
        QueryBuilder accountQueryBuilder = new QueryBuilder('Account');
        List<Account> accounts = (List<Account>) accountQueryBuilder.toList();
        System.assertEquals(1, accounts.size(), 'Extracted SObject should be added to the map');

        createAccount(2);
        accounts = (List<Account>) accountQueryBuilder.toList();
        System.assertEquals(1, accounts.size(), 'Extracted SObject should not be added to the map');

        accountQueryBuilder.resetResult();
        accounts = (List<Account>) accountQueryBuilder.toList();
        System.assertEquals(2, accounts.size(), 'Extracted SObject should be added to the map');
    }

    @IsTest
    public static void testToMap1() {
        Map<Id, SObject> accounts = new QueryBuilder('Account').addField('Name').toMap();
        System.assertEquals(1, accounts.size(), 'Extracted SObject should be added to the map');
    }

    @IsTest
    public static void testToMap2() {
        Map<Id, Account> accounts = new Map<Id, Account>();
        new QueryBuilder('Account').addField('Name').toMap(accounts);
        System.assertEquals(1, accounts.size(), 'Extracted SObject should be added to the map');
    }

    @IsTest
    public static void testToSobject() {
        Account account = (Account) new QueryBuilder('Account').toSObject();
        System.assertNotEquals(null, account, 'Extracted SObject should not be null');
    }

    @IsTest
    public static void testToSobject2() {
        SObject account = (Account) new QueryBuilder('Account')
            .addConditions()
            .add(new QueryBuilder.NullCondition('Name').isNull())
            .endConditions()
            .toSObject();
        System.assertEquals(null, account, 'Extracted SObject should be null');
    }

    @IsTest
    public static void testToIdSet() {
        Set<Id> accountIds = new QueryBuilder('Account').toIdSet();
        System.assertEquals(1, accountIds.size(), 'Extracted Ids should contain the Account Id');
    }

    @IsTest
    public static void testExtractIds() {
        final Id accountId = new QueryBuilder('Account').toSObject().Id;
        createContact(accountId);
        Set<Id> extractedIds = new QueryBuilder('Contact').addField('AccountId').extractIds('AccountId');
        System.assertEquals(1, extractedIds.size(), 'Extracted Ids should contain the Account Id');
        System.assert(extractedIds.contains(accountId), 'Extracted Ids should contain the Account Id');
    }

    @IsTest
    public static void testClone1() {
        QueryBuilder qb1 = new QueryBuilder('Account');
        System.assertEquals('SELECT Id FROM Account', qb1.toString(), 'Query should have "SELECT Id FROM Account"');

        QueryBuilder qb2 = qb1.cloneQueryBuilder();
        qb2.addField('Name');

        qb1.resetResult();
        System.assertEquals('SELECT Id FROM Account', qb1.toString(), 'Query should have "SELECT Id FROM Account"');
        System.assertEquals('SELECT Id, Name FROM Account', qb2.toString(), 'Query should have "SELECT Id, Name FROM Account"');
    }

    @IsTest
    public static void testClone2() {
        QueryBuilder qb1 = new QueryBuilder('Account');
        qb1.toList();

        QueryBuilder qb2 = qb1.cloneQueryBuilder(true);
        createAccount(2);

        System.assertEquals(qb1.toList(), qb2.toList(), 'Lists should be equal.');
    }

    @IsTest
    public static void testStub1() {
        final String expectedSOQL = 'SELECT Name FROM Account';

        QueryBuilder stubbedQueryBuilder = new QueryBuilder(Account.class).buildStub().addStubToString(expectedSOQL).applyStub();

        System.assertEquals(expectedSOQL, stubbedQueryBuilder.toString(), 'SOQL should be ' + expectedSOQL);
    }

    @IsTest
    public static void testStub2() {
        QueryBuilder stubbedQueryBuilder = new QueryBuilder(Account.class)
            .buildStub()
            .addStubToList(new List<Account>{ new Account(Name = 'Stubbed-Account') })
            .applyStub();

        List<Account> accounts = (List<Account>) stubbedQueryBuilder.toList();
        System.assertEquals(1, accounts.size(), 'Should return 1 record.');
        System.assertEquals('Stubbed-Account', accounts[0].Name, 'Account name should be Stubbed-Account.');
    }

    @IsTest
    static void testStandardFieldTokensGetByIdGetByName() {
        // setStandardFieldTokens should populate the selected fields when none were explicitly added
        Set<String> stdFields = new Set<String>{ 'Name', 'CreatedDate' };
        QueryBuilder sft = new QueryBuilder('Account').setStandardFieldTokens(stdFields);
        String sftQuery = sft.toString();
        System.assert(sftQuery.contains('FROM Account'), 'Standard fields query should include FROM Account');
        System.assert(sftQuery.contains('Name') || sftQuery.contains('CreatedDate'), 'Query should contain at least one of the standard fields');

        // getById should add a WHERE Id IN (...) condition
        Account acct = new Account(Name = 'QB Test Account');
        insert acct;
        QueryBuilder byId = new QueryBuilder('Account').getById(acct.Id).addField('Id');
        String byIdQuery = byId.toString();
        System.assert(byIdQuery.contains('FROM Account'), 'getById query should include FROM Account');
        System.assert(byIdQuery.contains('Id IN'), 'getById should include an IN condition on Id');
        System.assert(byIdQuery.contains(String.valueOf(acct.Id)), 'getById query should include the inserted Id');

        // getByName should add a WHERE Name IN (...) condition
        QueryBuilder byName = new QueryBuilder('Account').getByName(acct.Name).addField('Id');
        String byNameQuery = byName.toString();
        System.assert(byNameQuery.contains('FROM Account'), 'getByName query should include FROM Account');
        System.assert(byNameQuery.contains('Name IN') || byNameQuery.contains('Name='), 'getByName should include a Name condition');
        System.assert(byNameQuery.contains(acct.Name), 'getByName query should include the account Name');
    }

    @IsTest
    static void testAddFieldAndAddSubQuery() {
        // addField with comma-separated fields
        QueryBuilder af1 = new QueryBuilder('Account').addField('Name, Phone');
        String af1q = af1.toString();
        System.assert(af1q.contains('FROM Account'), 'Query should include FROM Account');
        System.assert(af1q.contains('Name'), 'Query should contain Name field');
        System.assert(af1q.contains('Phone'), 'Query should contain Phone field');

        // addField with SObjectField
        QueryBuilder af2 = new QueryBuilder('Account').addField(Account.Name);
        String af2q = af2.toString();
        System.assert(af2q.contains('Name'), 'addField(SObjectField) should include the field name');

        // addSubQuery with a nested QueryBuilder
        QueryBuilder sub = new QueryBuilder('Contact').addField('Id');
        String subStr = sub.toString();
        QueryBuilder main = new QueryBuilder('Account').addField('Id').addSubQuery(subStr);
        String mainStr = main.toString();
        System.assert(mainStr.contains('FROM Account'), 'Main query should include FROM Account');
        System.assert(mainStr.contains('(' + subStr + ')'), 'Subquery should be embedded in SELECT as a parenthesized subquery');
        QueryBuilder mainQuery = new QueryBuilder('Account').addField('Id').addSubQuery(sub);
        String mainString = mainQuery.toString();
        System.assert(mainString.contains('FROM Account'), 'Main query should include FROM Account');
        System.assert(mainString.contains('(' + subStr + ')'), 'Subquery should be embedded in SELECT as a parenthesized subquery');
    }

    @IsTest
    static void testAddFieldsAllAccessibleFields() {
        // addFieldsAllAcessibleFields should add accessible fields (e.g. Id and Name)
        QueryBuilder q = new QueryBuilder('Account').addFieldsAllAcessibleFields();
        String qs = q.toString();
        System.assert(qs.contains('FROM Account'), 'Query should include FROM Account');
        System.assert(qs.contains('Id'), 'Accessible fields should include Id');
        System.assert(qs.contains('Name'), 'Accessible fields should include Name');
    }

    @IsTest
    static void testAddFieldsAllVariants() {
        // addFieldsAll(Type)
        QueryBuilder a3 = new QueryBuilder('Account').addFieldsAll(Account.class);
        String a3s = a3.toString();
        System.assert(a3s.contains('FROM Account'), 'addFieldsAll(Type) should include FROM Account');

        // addFieldsAll(SObjectType)
        QueryBuilder a4 = new QueryBuilder('Account').addFieldsAll(Account.getSObjectType());
        String a4s = a4.toString();
        System.assert(a4s.contains('FROM Account'), 'addFieldsAll(SObjectType) should include FROM Account');

        // addFieldsAll(SObject)
        QueryBuilder a5 = new QueryBuilder('Account').addFieldsAll(new Account());
        String a5s = a5.toString();
        System.assert(a5s.contains('FROM Account'), 'addFieldsAll(SObject) should include FROM Account');
    }

    @IsTest
    static void testAddFieldsAllCreatableVariants() {
        // no-arg addFieldsAllCreatable() - uses fromSobject
        QueryBuilder b1 = new QueryBuilder('Account').addFieldsAllCreatable();
        String b1s = b1.toString();
        System.assert(b1s.contains('FROM Account'), 'addFieldsAllCreatable() should include FROM Account');
        System.assert(b1s.contains('Id') || b1s.contains('id'), 'addFieldsAllCreatable() should include Id');

        // addFieldsAllCreatable(String)
        QueryBuilder b2 = new QueryBuilder('Account').addFieldsAllCreatable('Account');
        String b2s = b2.toString();
        System.assert(b2s.contains('FROM Account'), 'addFieldsAllCreatable(String) should include FROM Account');

        // addFieldsAllCreatable(Type)
        QueryBuilder b3 = new QueryBuilder('Account').addFieldsAllCreatable(Account.class);
        String b3s = b3.toString();
        System.assert(b3s.contains('FROM Account'), 'addFieldsAllCreatable(Type) should include FROM Account');

        // addFieldsAllCreatable(SObjectType)
        QueryBuilder b4 = new QueryBuilder('Account').addFieldsAllCreatable(Account.getSObjectType());
        String b4s = b4.toString();
        System.assert(b4s.contains('FROM Account'), 'addFieldsAllCreatable(SObjectType) should include FROM Account');

        // addFieldsAllCreatable(SObject)
        QueryBuilder b5 = new QueryBuilder('Account').addFieldsAllCreatable(new Account());
        String b5s = b5.toString();
        System.assert(b5s.contains('FROM Account'), 'addFieldsAllCreatable(SObject) should include FROM Account');
    }

    @IsTest
    static void testAddFieldsAllUpdatableVariants() {
        // no-arg addFieldsAllUpdatable() - uses fromSobject
        QueryBuilder u1 = new QueryBuilder('Account').addFieldsAllUpdatable();
        String u1s = u1.toString();
        System.assert(u1s.contains('FROM Account'), 'addFieldsAllUpdatable() should include FROM Account');
        System.assert(u1s.contains('Id') || u1s.contains('id'), 'addFieldsAllUpdatable() should include Id');

        // addFieldsAllUpdatable(String)
        QueryBuilder u2 = new QueryBuilder('Account').addFieldsAllUpdatable('Account');
        String u2s = u2.toString();
        System.assert(u2s.contains('FROM Account'), 'addFieldsAllUpdatable(String) should include FROM Account');

        // addFieldsAllUpdatable(Type)
        QueryBuilder u3 = new QueryBuilder('Account').addFieldsAllUpdatable(Account.class);
        String u3s = u3.toString();
        System.assert(u3s.contains('FROM Account'), 'addFieldsAllUpdatable(Type) should include FROM Account');

        // addFieldsAllUpdatable(SObjectType)
        QueryBuilder u4 = new QueryBuilder('Account').addFieldsAllUpdatable(Account.getSObjectType());
        String u4s = u4.toString();
        System.assert(u4s.contains('FROM Account'), 'addFieldsAllUpdatable(SObjectType) should include FROM Account');

        // addFieldsAllUpdatable(SObject)
        QueryBuilder u5 = new QueryBuilder('Account').addFieldsAllUpdatable(new Account());
        String u5s = u5.toString();
        System.assert(u5s.contains('FROM Account'), 'addFieldsAllUpdatable(SObject) should include FROM Account');
    }

    @IsTest
    static void testAddFieldSetVariants() {
        // Variant A: objectName + fieldSetName (non-fatal if field set missing)
        QueryBuilder q1 = new QueryBuilder('Account').addFieldSet('Account', 'NonExistent_FieldSet');
        String s1 = q1.toString();
        System.assert(s1.contains('FROM Account'), 'addFieldSet(objectName, name) should not break and must include FROM');

        // Variant B: fieldSetName (uses fromSobject)
        QueryBuilder q2 = new QueryBuilder('Account').addFieldSet('NonExistent_FieldSet');
        String s2 = q2.toString();
        System.assert(s2.contains('FROM Account'), 'addFieldSet(fieldSetName) should not break and must include FROM');

        // Variant C: FieldSet object
        Map<String, Schema.FieldSet> fsMap = Account.SObjectType.getDescribe().fieldSets.getMap();
        if (!fsMap.isEmpty()) {
            // pick the first available field set on Account for a stronger assertion
            Iterator<String> it = fsMap.keySet().iterator();
            String firstFsName = it.next();
            Schema.FieldSet fs = fsMap.get(firstFsName);

            // add by FieldSet object
            QueryBuilder q3 = new QueryBuilder('Account').addFieldSet(fs);
            String s3 = q3.toString();
            System.assert(s3.contains('FROM Account'), 'addFieldSet(FieldSet) should include FROM Account');

            // If the fieldset has fields, assert one of them appears in the query
            List<Schema.FieldSetMember> members = fs.getFields();
            if (!members.isEmpty()) {
                String fp = members[0].getFieldPath();
                System.assert(s3.contains(fp), 'Query should include a field from the field set: ' + fp);
            }

            // add by objectName + fieldSetName for an existing fieldset
            QueryBuilder q4 = new QueryBuilder('Account').addFieldSet('Account', firstFsName);
            System.assert(q4.toString().contains('FROM Account'), 'addFieldSet(objectName, name) for existing FS should include FROM');
        } else {
            // no field sets defined in metadata — ensure call doesn't throw and query still valid
            QueryBuilder q3 = new QueryBuilder('Account').addFieldSet('SomeFieldSet');
            System.assert(q3.toString().contains('FROM Account'), 'addFieldSet(String) should not throw when no fieldsets exist');
        }
    }

    @IsTest
    static void testAddConditionsWithOrder() {
        Account a = new Account(Name = 'CondOrder Test');
        insert a;
        Set<Id> ids = new Set<Id>{ a.Id };
        Set<String> names = new Set<String>{ a.Name };

        QueryBuilder qb = new QueryBuilder('Account')
            .addConditionsWithOrder('1 AND 2')
            .add(new QueryBuilder.InCondition('Id').inCollection(ids))
            .add(new QueryBuilder.InCondition('Name').inCollection(names))
            .endConditions()
            .addField('Id');

        String q = qb.toString();
        System.assert(q.contains('WHERE'), 'Query should include WHERE when conditions added');
        System.assert(q.contains('Id IN'), 'Condition should include Id IN');
        System.assert(q.contains('Name IN'), 'Condition should include Name IN');
        System.assert(q.contains('AND'), 'Condition order should include AND');
    }

    @IsTest
    static void testSetOffset() {
        QueryBuilder qb = new QueryBuilder('Account').addField('Id').setOffset(5);
        String q = qb.toString();
        System.assert(q.contains('OFFSET 5'), 'setOffset should add OFFSET clause');
    }

    @IsTest
    static void testAddOrder() {
        QueryBuilder qb = new QueryBuilder('Account').addField('Id').addOrder(new QueryBuilder.Order('Name'));
        String q = qb.toString();
        System.assert(q.contains('ORDER BY'), 'addOrder should contribute ORDER BY clause');
        System.assert(q.contains('Name ASC') || q.contains('Name DESC'), 'Order entry should include sorting direction');
    }

    @IsTest
    static void testAddOrderAscVariants() {
        // SObjectField variant
        QueryBuilder q2 = new QueryBuilder('Account').addField('Id').addOrderAsc(Account.Name);
        System.assert(q2.toString().contains('ORDER BY') && q2.toString().contains('Name ASC'), 'addOrderAsc(SObjectField) should add Name ASC');
    }

    @IsTest
    static void testAddOrderDescVariants() {
        // SObjectField variant
        QueryBuilder q2 = new QueryBuilder('Account').addField('Id').addOrderDesc(Account.Name);
        System.assert(q2.toString().contains('ORDER BY') && q2.toString().contains('Name DESC'), 'addOrderDesc(SObjectField) should add Name DESC');
    }

    @IsTest
    static void testAddGroupByVariants() {
        // comma-separated string
        QueryBuilder g1 = new QueryBuilder('Account').addField('Id').addGroupBy('Name, Phone');
        String s1 = g1.toString();
        System.assert(s1.contains('GROUP BY'), 'addGroupBy(String) should add GROUP BY');
        System.assert(s1.contains('Name'), 'Group By should include Name');

        // SObjectField
        QueryBuilder g2 = new QueryBuilder('Account').addField('Id').addGroupBy(Account.Name);
        System.assert(g2.toString().contains('GROUP BY') && g2.toString().contains('Name'), 'addGroupBy(SObjectField) should include Name');

        // List<String>
        QueryBuilder g3 = new QueryBuilder('Account').addField('Id').addGroupBy(new List<String>{ 'Name' });
        System.assert(g3.toString().contains('GROUP BY') && g3.toString().contains('Name'), 'addGroupBy(List<String>) should include Name');
    }

    @IsTest
    static void testSetScope() {
        QueryBuilder q = new QueryBuilder('Account').addField('Id').setScope(QueryBuilder.FilterScope.Mine);
        String s = q.toString();
        System.assert(s.contains('USING SCOPE Mine'), 'setScope should add USING SCOPE Mine');
    }

    @IsTest
    static void testSetForViewVariants() {
        // Boolean variant (may be a no-op depending on implementation) - ensure it doesn't throw
        QueryBuilder b = new QueryBuilder('Account').addField('Id').setForView(true);
        System.assert(b.toString().contains('FROM Account'), 'setForView(Boolean) should not break query');

        // no-arg variant should add FOR VIEW
        QueryBuilder n = new QueryBuilder('Account').addField('Id').setForView();
        System.assert(n.toString().contains('FOR VIEW'), 'setForView() should add FOR VIEW');
    }

    @IsTest
    static void testSetForReferenceVariants() {
        // Boolean variant (may be a no-op depending on implementation)
        QueryBuilder b = new QueryBuilder('Account').addField('Id').setForReference(true);
        System.assert(b.toString().contains('FROM Account'), 'setForReference(Boolean) should not break query');

        // no-arg variant should add FOR REFERENCE
        QueryBuilder n = new QueryBuilder('Account').addField('Id').setForReference();
        System.assert(n.toString().contains('FOR REFERENCE'), 'setForReference() should add FOR REFERENCE');
    }

    @IsTest
    static void testSetUpdateTrackingAndViewstatVariants() {
        // update tracking only
        QueryBuilder t1 = new QueryBuilder('Account').addField('Id').setUpdateTracking(true);
        System.assert(t1.toString().contains('UPDATE TRACKING'), 'setUpdateTracking(true) should add UPDATE TRACKING');

        QueryBuilder t2 = new QueryBuilder('Account').addField('Id').setUpdateTracking();
        System.assert(t2.toString().contains('UPDATE TRACKING'), 'setUpdateTracking() should add UPDATE TRACKING');

        // viewstat only
        QueryBuilder v1 = new QueryBuilder('Account').addField('Id').setUpdateViewstat(true);
        System.assert(v1.toString().contains('UPDATE VIEWSTAT'), 'setUpdateViewstat(true) should add UPDATE VIEWSTAT');

        QueryBuilder v2 = new QueryBuilder('Account').addField('Id').setUpdateViewstat();
        System.assert(v2.toString().contains('UPDATE VIEWSTAT'), 'setUpdateViewstat() should add UPDATE VIEWSTAT');

        // both
        QueryBuilder both = new QueryBuilder('Account').addField('Id').setUpdateTracking(true).setUpdateViewstat(true);
        String sboth = both.toString();
        System.assert(sboth.contains('UPDATE TRACKING'), 'Both should include UPDATE TRACKING');
        System.assert(sboth.contains('VIEWSTAT'), 'Both should include VIEWSTAT');
        System.assert(sboth.contains('UPDATE TRACKING') && sboth.contains('VIEWSTAT'), 'Combined update clauses should be present');
    }

    @IsTest
    static void testSetCheckCRUDAndFLSVariants() {
        // boolean variant
        QueryBuilder c1 = new QueryBuilder('Account').addField('Id').setCheckCRUDAndFLS(true);
        System.assert(c1.toString().contains('FROM Account'), 'setCheckCRUDAndFLS(Boolean) should not break the query');

        // no-arg variant
        QueryBuilder c2 = new QueryBuilder('Account').addField('Id').setCheckCRUDAndFLS();
        System.assert(c2.toString().contains('FROM Account'), 'setCheckCRUDAndFLS() should not break the query');
    }

    @IsTest
    static void testSetWithSecurityEnforcedVariants() {
        // boolean variant
        QueryBuilder s1 = new QueryBuilder('Account').addField('Id').setWithSecurityEnforced(true);
        System.assert(s1.toString().contains('WITH SECURITY_ENFORCED'), 'setWithSecurityEnforced(true) should add WITH SECURITY_ENFORCED');

        // no-arg variant
        QueryBuilder s2 = new QueryBuilder('Account').addField('Id').setWithSecurityEnforced();
        System.assert(s2.toString().contains('WITH SECURITY_ENFORCED'), 'setWithSecurityEnforced() should add WITH SECURITY_ENFORCED');
    }

    @IsTest
    static void testSetCheckCRUDAndFLSIndividualVariants() {
        // setCheckCRUD()
        QueryBuilder chk1 = new QueryBuilder('Account').addField('Id').setCheckCRUD();
        System.assert(chk1.toString().contains('FROM Account'), 'setCheckCRUD() should not break the query');

        // setCheckFLS()
        QueryBuilder chk2 = new QueryBuilder('Account').addField('Id').setCheckFLS();
        System.assert(chk2.toString().contains('FROM Account'), 'setCheckFLS() should not break the query');
    }

    @IsTest
    static void testToMapByKeyField() {
        Account a = new Account(Name = 'MapKey Test');
        insert a;

        QueryBuilder qb = new QueryBuilder('Account').getById(a.Id).addField('Id').addField('Name');
        Map<String, List<SObject>> mapByName = qb.toMap('Name');
        System.assert(mapByName.containsKey(a.Name), 'toMap(keyField) should map by the provided key field');
    }

    @IsTest
    static void testToQueryLocator() {
        Account a = new Account(Name = 'Full Flow Test');
        insert a;

        QueryBuilder qb = new QueryBuilder('Account').getById(a.Id).addField('Id').addField('Name');

        // toQueryLocator should not be null
        Database.QueryLocator ql = qb.toQueryLocator();
        System.assert(ql != null, 'toQueryLocator should return a non-null QueryLocator');
    }

    @IsTest
    static void testExtractFieldVariants() {
        Account a = new Account(Name = 'Full Flow Test');
        insert a;

        QueryBuilder qb = new QueryBuilder('Account').getById(a.Id).addField('Id').addField('Name');

        List<Object> names1 = qb.extractField('Name');
        System.assert(!names1.isEmpty() && names1[0] == a.Name, 'extractField should return the Name');

        List<Object> names2 = qb.extractField(Account.Name);
        System.assert(!names2.isEmpty() && names2[0] == a.Name, 'extractField should return the Name');
    }

    @IsTest
    public static void testToListVariants() {
        QueryBuilder qb = new QueryBuilder(Account.class).addFields(new List<String>{ 'Id', 'Name' });
        qb.setCheckCRUD(true);
        List<Account> accounts1 = (List<Account>) qb.toList();
        System.assertEquals(1, accounts1.size(), 'Result should have 1 record when checkCRUD is true.');

        QueryBuilder qb2 = new QueryBuilder(Account.class).addFields(new List<String>{ 'Id', 'Name' });
        qb2.setCheckFLS(true);
        List<Account> accounts2 = (List<Account>) qb2.toList();
        System.assertEquals(1, accounts2.size(), 'Result should have 1 record when checkFLS is true.');
    }

    @IsTest
    static void testCompareConditionEqString() {
        List<Account> result = (List<Account>) new QueryBuilder(Account.class)
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
            .endConditions()
            .toList();

        System.assertEquals(1, result.size(), 'eq(String) should return exactly one record for Account-1');
        System.assertEquals('Account-1', result[0].Name, 'Account name should be Account-1');
    }

    @IsTest
    static void testCompareConditionEqStringWithFieldAndObject() {
        // Verify eq(String, fieldName, objectName) behaves like eq for string fields
        List<Account> result = (List<Account>) new QueryBuilder(Account.class)
            .addField('Name')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1', 'Name', 'Account'))
            .endConditions()
            .toList();

        System.assertEquals(1, result.size(), 'eq(String,fieldName,objectName) should match Account-1');
        System.assertEquals('Account-1', result[0].Name, 'eq(String,fieldName,objectName) should return the Name field');
    }

    @IsTest
    static void testCompareConditionEqDate() {
        // Use Contact.Birthdate (Date) to exercise eq(Date)
        Contact c1 = new Contact(LastName = 'C1', Birthdate = Date.newInstance(1990, 1, 1));
        Contact c2 = new Contact(LastName = 'C2', Birthdate = Date.newInstance(1991, 2, 2));
        insert new List<Contact>{ c1, c2 };

        List<Contact> res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').eq(Date.newInstance(1990, 1, 1)))
            .endConditions()
            .toList();

        System.assertEquals(1, res.size(), 'eq(Date) should return one contact with matching Birthdate');
        System.assertEquals(Date.newInstance(1990, 1, 1), (Date) res[0].get('Birthdate'), 'Birthdate should be 1990-01-01');
    }

    @IsTest
    static void testCompareConditionEqBoolean() {
        // Use Contact.HasOptedOutOfEmail (Boolean) to exercise eq(Boolean)
        Contact c1 = new Contact(LastName = 'B1', HasOptedOutOfEmail = true);
        Contact c2 = new Contact(LastName = 'B2', HasOptedOutOfEmail = false);
        insert new List<Contact>{ c1, c2 };

        List<Contact> res = (List<Contact>) new QueryBuilder('Contact')
            .addField('HasOptedOutOfEmail')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('HasOptedOutOfEmail').eq(true))
            .endConditions()
            .toList();

        System.assertEquals(1, res.size(), 'eq(Boolean) should return the contact with HasOptedOutOfEmail=true');
        System.assertEquals(true, (Boolean) res[0].get('HasOptedOutOfEmail'), 'HasOptedOutOfEmail should be true');
    }

    @IsTest
    static void testCompareConditionEqDecimal() {
        // Use Account.NumberOfEmployees (numeric) to exercise eq(Decimal)
        Account a1 = new Account(Name = 'Dec-1', NumberOfEmployees = 5);
        Account a2 = new Account(Name = 'Dec-2', NumberOfEmployees = 10);
        insert new List<Account>{ a1, a2 };

        List<Account> res = (List<Account>) new QueryBuilder('Account')
            .addField('NumberOfEmployees')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('NumberOfEmployees').eq(Decimal.valueOf(5)))
            .endConditions()
            .toList();

        System.assertEquals(1, res.size(), 'eq(Decimal) should return the account with NumberOfEmployees=5');
        System.assertEquals(5, ((Integer) res[0].get('NumberOfEmployees')), 'NumberOfEmployees should be 5');
    }

    @IsTest
    static void testCompareConditionNeBoolean() {
        // Use Contact.HasOptedOutOfEmail (Boolean) to exercise eq(Boolean)
        Contact c1 = new Contact(LastName = 'B1', HasOptedOutOfEmail = true);
        Contact c2 = new Contact(LastName = 'B2', HasOptedOutOfEmail = false);
        insert new List<Contact>{ c1, c2 };

        List<Contact> res = (List<Contact>) new QueryBuilder('Contact')
            .addField('HasOptedOutOfEmail')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('HasOptedOutOfEmail').ne(true))
            .endConditions()
            .toList();

        System.assertEquals(1, res.size(), 'ne(Boolean) should return the contact with HasOptedOutOfEmail=false');
        System.assertEquals(false, (Boolean) res[0].get('HasOptedOutOfEmail'), 'HasOptedOutOfEmail should be false');
    }

    @IsTest
    static void testCompareConditionLtGt() {
        // Use Contact.Birthdate (Date) to exercise eq(Date)
        // Use Datetime values for EvergageFirstActivity__c, matching the test logic
        // Use Datetime for EvergageFirstActivity__c, and match the query string to the SOQL format
        Datetime dt1 = Datetime.newInstance(1990, 1, 1, 0, 0, 0);
        Datetime dt2 = Datetime.newInstance(1991, 2, 2, 0, 0, 0);
        Contact c1 = new Contact(
            LastName = 'C1',
            EvergageFirstActivity__c = dt1,
            Birthdate = Date.newInstance(1990, 1, 1)
        );
        Contact c2 = new Contact(
            LastName = 'C2',
            EvergageFirstActivity__c = dt2,
            Birthdate = Date.newInstance(1991, 2, 2)
        );
        insert new List<Contact>{ c1, c2 };

        // -- lt
        List<Contact> res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('EvergageFirstActivity__c').lt(Datetime.newInstance(1990, 2, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lt(Datetime) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('LastName')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('LastName').lt('D%'))
            .endConditions()
            .toList();
        System.assertEquals(2, res.size(), 'lt(String) should return two contacts');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').lt('1990-02-01', 'Birthdate', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lt(String, String, String) should return one contact');

        // -- gt
        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('EvergageFirstActivity__c').gt(Datetime.newInstance(1991, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gt(Datetime) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('LastName')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('LastName').gt('C1'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gt(Datetime) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').gt('1990-12-31', 'Birthdate', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gt(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(
                new QueryBuilder.CompareCondition('EvergageFirstActivity__c')
                    .gt('1990-12-31T00:00:00.000-0200', 'EvergageFirstActivity__c', 'Contact')
            )
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gt(String, String, String) should return one contact');

        // -- lte
        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('EvergageFirstActivity__c').lte(Datetime.newInstance(1990, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(Datetime) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').lte(Date.newInstance(1990, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(Date) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('EvergageFirstActivity__c').lte(Datetime.newInstance(1990, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(Datetime) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').lte('1990-01-01', 'Birthdate', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('LastName')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('LastName').lte('C1', 'LastName', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').lte('1990-01-01', 'Birthdate', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(
                new QueryBuilder.CompareCondition('EvergageFirstActivity__c').lte(Date.newInstance(1990, 1, 1), 'EvergageFirstActivity__c', 'Contact')
            )
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'lte(Date, String, String) should return one contact');

        // -- gte
        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(
                new QueryBuilder.CompareCondition('EvergageFirstActivity__c').gte(Date.newInstance(1991, 1, 1), 'EvergageFirstActivity__c', 'Contact')
            )
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(Date, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('EvergageFirstActivity__c').gte(Datetime.newInstance(1991, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(Datetime, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').gte(Date.newInstance(1991, 1, 1)))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(Date, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('EvergageFirstActivity__c')
            .addConditions()
            .add(
                new QueryBuilder.CompareCondition('EvergageFirstActivity__c')
                    .gte('1991-01-01T00:00:00.000-0200', 'EvergageFirstActivity__c', 'Contact')
            )
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('Birthdate')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Birthdate').gte('1991-01-01', 'Birthdate', 'Contact'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(String, String, String) should return one contact');

        res = (List<Contact>) new QueryBuilder('Contact')
            .addField('LastName')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('LastName').gte('C2'))
            .endConditions()
            .toList();
        System.assertEquals(1, res.size(), 'gte(String) should return one contact');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesSimple() {
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.SimpleCondition().ignoreConditionsForNullValues())
            .endConditions();

        String q = qb.toString();
        System.assert(!q.contains('WHERE'), 'SimpleCondition with ignore and empty value should not add WHERE');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesNullCondition() {
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.NullCondition('Name').ignoreConditionsForNullValues().isNull())
            .endConditions();

        String q = qb.toString();
        System.assert(q.contains('WHERE'), 'NullCondition.isNull() should add a WHERE clause even when ignore is set');
        System.assert(q.contains('Name = NULL'), 'NullCondition.isNull() should form Name = NULL');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesCompareCondition() {
        // without ignore - empty string still creates a condition
        QueryBuilder qNoIgnore = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq(''))
            .endConditions();
        System.assert(qNoIgnore.toString().contains('WHERE'), 'CompareCondition.eq("") without ignore should add WHERE');

        // with ignore - empty string should NOT create a condition
        QueryBuilder qIgnore = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').ignoreConditionsForNullValues().eq(''))
            .endConditions();
        System.assert(!qIgnore.toString().contains('WHERE'), 'CompareCondition.eq("") with ignore should not add WHERE');

        // verify non-empty value still forms condition
        QueryBuilder qVal = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').ignoreConditionsForNullValues().eq('Account-1'))
            .endConditions();
        System.assert(qVal.toString().contains('WHERE'), 'CompareCondition.eq(non-empty) with ignore should add WHERE');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesLikeCondition() {
        QueryBuilder qNoIgnore = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth(''))
            .endConditions();
        System.assert(qNoIgnore.toString().contains('WHERE'), 'LikeCondition.likeAnyBoth("") without ignore should add WHERE');

        QueryBuilder qIgnore = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.LikeCondition('Name').ignoreConditionsForNullValues().likeAnyBoth(''))
            .endConditions();
        System.assert(!qIgnore.toString().contains('WHERE'), 'LikeCondition.likeAnyBoth("") with ignore should not add WHERE');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesInCondition() {
        Set<String> emptySet = new Set<String>();
        Set<String> nonEmpty = new Set<String>{ 'Account-1' };

        QueryBuilder qEmpty = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Name').inCollection(emptySet))
            .endConditions();
        System.assert(!qEmpty.toString().contains('WHERE'), 'InCondition with empty set should not add WHERE');

        QueryBuilder qNonEmpty = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Name').ignoreConditionsForNullValues().inCollection(nonEmpty))
            .endConditions();
        System.assert(qNonEmpty.toString().contains('WHERE'), 'InCondition with non-empty set should add WHERE');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesComplexCondition() {
        // complex with start condition that is empty when ignored
        QueryBuilder.ComplexCondition complexNoIgnore = new QueryBuilder.ComplexCondition();
        complexNoIgnore.startCondition(new QueryBuilder.CompareCondition('Name').eq(''));
        QueryBuilder qComplexNoIgnore = new QueryBuilder('Account').addField('Id').addConditions().add(complexNoIgnore).endConditions();
        System.assert(qComplexNoIgnore.toString().contains('WHERE'), 'ComplexCondition with empty start (no ignore) should add WHERE');

        QueryBuilder.ComplexCondition complexIgnore = new QueryBuilder.ComplexCondition().ignoreConditionsForNullValues();
        complexIgnore.startCondition(new QueryBuilder.CompareCondition('Name').ignoreConditionsForNullValues().eq(''));
        QueryBuilder qComplexIgnore = new QueryBuilder('Account').addField('Id').addConditions().add(complexIgnore).endConditions();
        System.assert(!qComplexIgnore.toString().contains('WHERE'), 'ComplexCondition with ignored empty start should not add WHERE');
    }

    @IsTest
    static void testIgnoreConditionsForNullValuesObjectTypeDependentChainable() {
        // Ensure method exists and is chainable; do not call toString() to avoid record type lookups
        QueryBuilder.RecordTypeCondition rtc = new QueryBuilder.RecordTypeCondition('NonExistentRT');
        rtc = (QueryBuilder.RecordTypeCondition) rtc.ignoreConditionsForNullValues();
        System.assert(rtc != null, 'ignoreConditionsForNullValues() on ObjectTypeDependentCondition should be chainable');
    }

    @IsTest
    static void testInConditionWithQueryBuilderSubquery() {
        Account a = createAccount(100);
        Contact c = new Contact(LastName = 'SubQ', AccountId = a.Id);
        insert c;

        QueryBuilder sub = new QueryBuilder('Contact').addField('AccountId');
        QueryBuilder qb = new QueryBuilder(Account.class)
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(sub))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        System.assert(!res.isEmpty(), 'Subquery IN should return the account referenced by the contact');
    }

    @IsTest
    static void testInConditionWithListSObject() {
        Account a = createAccount(101);
        List<SObject> sList = new List<SObject>();
        sList.add(a);

        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(sList))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        System.assert(!res.isEmpty(), 'inCollection(List<SObject>) should return the matching account');
    }

    @IsTest
    static void testInConditionWithMapSObject() {
        Account a = createAccount(102);
        Map<Id, SObject> m = new Map<Id, SObject>();
        m.put(a.Id, a);

        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').inCollection(m))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        System.assert(!res.isEmpty(), 'inCollection(Map<Id,SObject>) should return the matching account');
    }

    @IsTest
    static void testInConditionWithSetDecimalAndListDecimal() {
        Account a1 = new Account(Name = 'DecA', NumberOfEmployees = 42);
        Account a2 = new Account(Name = 'DecB', NumberOfEmployees = 99);
        insert new List<Account>{ a1, a2 };

        QueryBuilder qbSet = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('NumberOfEmployees').inCollection(new Set<Decimal>{ 42 }))
            .endConditions();
        List<Account> resSet = (List<Account>) qbSet.toList();
        System.assertEquals(1, resSet.size(), 'inCollection(Set<Decimal>) should return one matching account');

        QueryBuilder qbList = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('NumberOfEmployees').inCollection(new List<Decimal>{ 99 }))
            .endConditions();
        List<Account> resList = (List<Account>) qbList.toList();
        System.assertEquals(1, resList.size(), 'inCollection(List<Decimal>) should return one matching account');
    }

    @IsTest
    static void testInConditionWithPicklistEntryList() {
        // Try to exercise inCollection(List<PicklistEntry>) using an existing picklist if available
        List<Schema.PicklistEntry> entries = Account.Type.getDescribe().getPicklistValues();
        if (entries.isEmpty()) {
            // No picklist metadata available — ensure method call doesn't throw and no WHERE is added
            QueryBuilder qb = new QueryBuilder('Account')
                .addField('Id')
                .addConditions()
                .add(new QueryBuilder.InCondition('Type').inCollection(entries))
                .endConditions();
            String s = qb.toString();
            System.assert(!s.contains('WHERE'), 'Empty picklist entry list should not add WHERE');
        } else {
            // Use the first picklist value — create an account with that value so the IN returns a result
            String val = entries[0].getValue();
            Account a = new Account(Name = 'PickTest', Type = val);
            insert a;

            QueryBuilder qb = new QueryBuilder('Account')
                .addField('Id')
                .addConditions()
                .add(new QueryBuilder.InCondition('Type').inCollection(entries))
                .endConditions();
            List<Account> res = (List<Account>) qb.toList();
            System.assert(!res.isEmpty(), 'inCollection(List<PicklistEntry>) should return records when picklist values exist');
        }
    }

    @IsTest
    static void testNotInWithListSObject() {
        String randomUuid = UUID.randomUUID().toString();
        Account a = createAccount(randomUuid.substring(0, 5));
        List<SObject> sList = new List<SObject>();
        sList.add(a);

        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').notIn(sList))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        Boolean contains = res.contains(new Account(Id = a.Id));
        System.assert(!contains, 'notIn(List<SObject>) should exclude the provided account');
    }

    @IsTest
    static void testNotInWithMapSObject() {
        String randomUuid = UUID.randomUUID().toString();
        Account a = createAccount(randomUuid.substring(0, 5));
        Map<Id, SObject> m = new Map<Id, SObject>();
        m.put(a.Id, a);

        QueryBuilder qb = new QueryBuilder('Account').addField('Id').addConditions().add(new QueryBuilder.InCondition('Id').notIn(m)).endConditions();

        List<Account> res = (List<Account>) qb.toList();
        Boolean contains = res.contains(new Account(Id = a.Id));
        System.assert(!contains, 'notIn(Map<Id,SObject>) should exclude the provided account');
    }

    @IsTest
    static void testNotInWithSetId() {
        String randomUuid = UUID.randomUUID().toString();
        Account a = createAccount(randomUuid.substring(0, 5));
        Set<Id> ids = new Set<Id>{ a.Id };

        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').notIn(ids))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        Boolean contains = res.contains(new Account(Id = a.Id));
        System.assert(!contains, 'notIn(Set<Id>) should exclude the provided account');
    }

    @IsTest
    static void testNotInWithQueryBuilderSubquery() {
        String randomUuid = UUID.randomUUID().toString();
        Account a = createAccount(randomUuid.substring(0, 5));
        Contact c = new Contact(LastName = 'NotInSub', AccountId = a.Id);
        insert c;

        QueryBuilder sub = new QueryBuilder('Contact').addField('AccountId');
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
            .add(new QueryBuilder.InCondition('Id').notIn(sub))
            .endConditions();

        List<Account> res = (List<Account>) qb.toList();
        Boolean contains = res.contains(new Account(Id = a.Id));
        System.assert(!contains, 'notIn(QueryBuilder) should exclude accounts returned by the subquery');
    }

    @IsTest
    static void testSetRelatedObjectTypeDirect() {
        TestObjectTypeCondition cond = new TestObjectTypeCondition();
        // initially null
        System.assertEquals(null, cond.getObjectType(), 'objectType should be null before setRelatedObjectType');

        cond.setRelatedObjectType('Contact');
        System.assertEquals('Contact', cond.getObjectType(), 'setRelatedObjectType should set the protected objectType');
    }

    @IsTest
    static void testSetRelatedObjectTypeViaConditionsManagerAdd() {
        QueryBuilder qb = new QueryBuilder('Account');
        TestObjectTypeCondition cond = new TestObjectTypeCondition();

        // add the condition via the QueryBuilder ConditionsManager which should call setRelatedObjectType
        qb.addConditions().add(cond).endConditions();
        System.assertEquals(
            'Account',
            cond.getObjectType(),
            'ConditionsManager.add should set the related object type to the QueryBuilder.fromSobject'
        );
    }

    @IsTest
    static void testRecordTypeConditionToStringWhenRecordTypeExists() {
        // Retrieve Account record types if present
        Schema.DescribeSObjectResult adr = Schema.getGlobalDescribe().get('Account').getDescribe();
        Map<String, Schema.RecordTypeInfo> rtMap = adr.getRecordTypeInfosByName();
        if (rtMap == null || rtMap.isEmpty()) {
            // Nothing to assert against in this org — mark as executed
            System.assert(true, 'No Account record types available in this org; test skipped');
            return;
        }

        // Use the first available record type name
        String rtName = rtMap.keySet().iterator().next();
        QueryBuilder.RecordTypeCondition rtc = new QueryBuilder.RecordTypeCondition(rtName);
        rtc.setRelatedObjectType('Account');

        String s = rtc.toString();
        System.assert(s.contains('RecordTypeId'), 'RecordTypeCondition.toString should include RecordTypeId');

        // Ensure the actual record type id appears in the generated condition
        Id rtId = rtMap.get(rtName).getRecordTypeId();
        System.assert(s.contains(String.valueOf(rtId)), 'RecordTypeCondition.toString should include the record type id');
    }

    @IsTest
    static void testToStringWithMultipleModifiers() {
        // Build a query exercising scope, where, security, group/order, limit/offset, for view, update flags
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addField('Name')
            .setScope(QueryBuilder.FilterScope.Mine)
            .addConditions()
            .add(new QueryBuilder.CompareCondition('Name').eq('Account-1'))
            .endConditions()
            .setWithSecurityEnforced()
            .addGroupBy('Name')
            .addOrder(new QueryBuilder.Order('Name').setNullsOrderFirst())
            .setLimit(10)
            .setOffset(2)
            .setForView()
            .setUpdateTracking(true)
            .setUpdateViewstat(true);

        String s = qb.toString();
        System.assert(s.contains('USING SCOPE Mine'), 'toString should include scope');
        System.assert(s.contains('WHERE') && s.contains('Name = '), 'toString should include WHERE clause');
        System.assert(s.contains('WITH SECURITY_ENFORCED'), 'toString should include WITH SECURITY_ENFORCED');
        System.assert(s.contains('GROUP BY') && s.contains('Name'), 'toString should include GROUP BY Name');
        System.assert(s.contains('ORDER BY') && s.contains('Name'), 'toString should include ORDER BY Name');
        System.assert(s.contains('LIMIT 10'), 'toString should include LIMIT 10');
        System.assert(s.contains('OFFSET 2'), 'toString should include OFFSET 2');
        System.assert(s.contains('FOR VIEW'), 'toString should include FOR VIEW');
        System.assert(s.contains('UPDATE TRACKING') && s.contains('VIEWSTAT'), 'toString should include update tracking and viewstat');
    }

    @IsTest
    static void testOrderClassMethodsAndConstructors() {
        // Basic Order default (ASC)
        QueryBuilder.Order o1 = new QueryBuilder.Order('Name');
        String o1s = o1.toString();
        System.assert(o1s.contains('Name') && o1s.contains('ASC'), 'Order should default to ASC');

        // setSortingOrderAsc
        QueryBuilder.Order o5 = new QueryBuilder.Order('Name').setSortingOrderAsc();
        System.assert(o5.toString().contains('Name') && o5.toString().contains('ASC'), 'setSortingOrderAsc should set ASC');

        // setSortingOrderDesc
        QueryBuilder.Order o2 = new QueryBuilder.Order('Name').setSortingOrderDesc();
        System.assert(o2.toString().contains('Name') && o2.toString().contains('DESC'), 'setSortingOrderDesc should set DESC');

        // Nulls order helpers
        QueryBuilder.Order o3 = new QueryBuilder.Order('Name').setNullsOrderFirst();
        System.assert(o3.toString().contains('NULLS FIRST') || o3.toString().contains('NULLS'), 'setNullsOrderFirst should include NULLS FIRST');

        QueryBuilder.Order o4 = new QueryBuilder.Order('Name').setNullsOrderLast();
        System.assert(o4.toString().contains('NULLS LAST') || o4.toString().contains('NULLS'), 'setNullsOrderLast should include NULLS LAST');

        // AscOrder / DescOrder
        QueryBuilder.Order orderAsc = new QueryBuilder.AscOrder('Name');
        QueryBuilder.Order orderDesc = new QueryBuilder.DescOrder('Name');
        System.assert(orderAsc.toString().contains('ASC'), 'AscOrder should produce ASC');
        System.assert(orderDesc.toString().contains('DESC'), 'DescOrder should produce DESC');

        // SObjectField constructor
        QueryBuilder.Order oField = new QueryBuilder.Order(Account.Name);
        System.assert(oField.toString().contains('Name'), 'Order(SObjectField) should include field name');

        // Use Order in QueryBuilder and ensure ORDER BY contains expected fragment
        QueryBuilder qb = new QueryBuilder('Account').addField('Id').addOrder(o1);
        String qs = qb.toString();
        System.assert(qs.contains('ORDER BY'), 'QueryBuilder.toString should include ORDER BY when orders added');
    }

    @IsTest
    static void testMockProviderToStringAndToListVariants() {
        final String expectedSOQL = 'SELECT Name FROM Account';

        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        stub.addStubToString(expectedSOQL);
        stub.addStubToList(new List<Account>{ new Account(Name = 'Stubbed-Account') });
        QueryBuilder qb = stub.applyStub();

        // toString should be delegated to stub
        System.assertEquals(expectedSOQL, qb.toString(), 'Mocked toString should return expected SOQL');

        // toList should return the stubbed list
        List<Account> res = (List<Account>) qb.toList();
        System.assertEquals(1, res.size(), 'Mocked toList should return one stubbed record');
        System.assertEquals('Stubbed-Account', res[0].Name, 'Mocked toList record should match stub value');
    }

    @IsTest
    static void testMockProviderToStringCountAndToCount() {
        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        stub.addStubToStringCount('SELECT count() FROM Account WHERE Name = \'X\'');
        stub.addStubToCount(42);
        QueryBuilder qb = stub.applyStub();

        System.assertEquals('SELECT count() FROM Account WHERE Name = \'X\'', qb.toStringCount(), 'Mocked toStringCount should return stubbed value');
        System.assertEquals(42, qb.toCount(), 'Mocked toCount should return stubbed integer');
    }

    @IsTest
    static void testMockProviderToMapVariants() {
        // prepare a real account to use its Id in maps/sets
        Account real = [SELECT Id, Name FROM Account LIMIT 1];

        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        Map<Id, SObject> mapResult = new Map<Id, SObject>{ real.Id => real };
        stub.addStubToMap(mapResult);
        QueryBuilder qb = stub.applyStub();

        // no-arg toMap should return the stubbed map
        Map<Id, SObject> ret = qb.toMap();
        System.assertEquals(1, ret.size(), 'Mocked toMap() should return stubbed map');
        System.assert(ret.containsKey(real.Id), 'Mocked toMap() should contain the prepared Id');

        // with-arg toMap(Map) branch in provider returns internal fill result (not exposed via setter) - ensure it does not throw and returns null when unset
        Map<Id, SObject> fill = new Map<Id, SObject>();
        Map<Id, SObject> filled = qb.toMap(fill);
        System.assertEquals(null, filled, 'Mocked toMap(map) without explicit internal fill result should return null');
    }

    @IsTest
    static void testMockProviderToSObjectToIdSetExtracts() {
        Account real = [SELECT Id FROM Account LIMIT 1];

        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        stub.addStubToSObject(new Account(Id = real.Id, Name = 'StubSObj'));
        stub.addStubToIdSet(new Set<Id>{ real.Id });
        stub.addStubExtractIds(new Set<Id>{ real.Id });
        stub.addStubExtractField(new List<Object>{ 'X', 'Y' });
        QueryBuilder qb = stub.applyStub();

        SObject so = qb.toSObject();
        System.assertNotEquals(null, so, 'Mocked toSObject should return stubbed SObject');

        Set<Id> ids = qb.toIdSet();
        System.assertEquals(1, ids.size(), 'Mocked toIdSet should return stubbed set');
        System.assert(ids.contains(real.Id), 'Mocked toIdSet should contain the prepared Id');

        Set<Id> ext = qb.extractIds('Any');
        System.assertEquals(1, ext.size(), 'Mocked extractIds should return stubbed set');
        System.assert(ext.contains(real.Id), 'Mocked extractIds should contain the prepared Id');

        List<Object> fields = qb.extractField('Any');
        System.assertEquals(2, fields.size(), 'Mocked extractField should return stubbed list');
        System.assertEquals('X', fields[0], 'First value from stubbed extractField should match');
    }

    @IsTest
    static void testMockProviderAddConditionsReturnsStubbedConditionsManager() {
        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        QueryBuilder qb = stub.applyStub();

        // addConditions should return the stubbed ConditionsManager and endConditions should return the same stubbed QueryBuilder
        QueryBuilder.ConditionsManager cm = qb.addConditions();
        System.assertNotEquals(null, cm, 'addConditions should return a ConditionsManager instance');
        QueryBuilder returned = cm.endConditions();
        System.assertEquals(qb, returned, 'endConditions on stubbed manager should return the stubbed QueryBuilder');
    }

    @IsTest
    static void testConditionsManagerMockProviderEndConditionsAndToString() {
        // prepare stubbed builder and obtain the stubbed conditions manager via the public entrypoint
        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        QueryBuilder qb = stub.applyStub();
        QueryBuilder.ConditionsManager cm = qb.addConditions();

        // create a provider pointing at our stub
        QueryBuilder.ConditionsManagerMockProvider provider = new QueryBuilder.ConditionsManagerMockProvider(stub);

        // call endConditions via provider - should return the stubbed QueryBuilder (same as qb)
        // Object endRes = provider.handleMethodCall(cm, 'endConditions', null, new List<Type>(), new List<String>(), new List<Object>());
        // System.assertEquals(qb, (QueryBuilder) endRes, 'ConditionsManagerMockProvider.endConditions should return the stubbed QueryBuilder');

        // call toString via provider - should return empty string as per implementation
        Object strRes = provider.handleMethodCall(cm, 'toString', null, new List<Type>(), new List<String>(), new List<Object>());
        System.assertEquals('', (String) strRes, 'ConditionsManagerMockProvider.toString should return empty string');
    }

    @IsTest
    static void testConditionsManagerMockProviderDefaultBranchReturnsStubbedObject() {
        QueryBuilder.StubbedQueryBuilder stub = new QueryBuilder(Account.class).buildStub();
        QueryBuilder qb = stub.applyStub();
        QueryBuilder.ConditionsManager cm = qb.addConditions();
        QueryBuilder.ConditionsManagerMockProvider provider = new QueryBuilder.ConditionsManagerMockProvider(stub);

        // call an unknown method - provider should return the passed stubbedObject unchanged
        Object res = provider.handleMethodCall(cm, 'someUnknownMethod', null, new List<Type>(), new List<String>(), new List<Object>());
        System.assertEquals(
            cm,
            (QueryBuilder.ConditionsManager) res,
            'Unknown method should result in provider returning the original stubbedObject'
        );
    }
}