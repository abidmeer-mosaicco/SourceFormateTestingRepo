@IsTest
private class ExecutionControllerTest {
	@IsTest
	static void testExecuteOnce() {
		String key = 'TestKey';
		System.assertEquals(true, ExecutionController.executeOnce(key));
		System.assertEquals(false, ExecutionController.executeOnce(key));
	}

	@IsTest
	static void testStartStopResetWithIds() {
		String baseKey = 'MyProcess';
		Set<Id> ids = new Set<Id>{ '001000000000001AAA', '001000000000002AAA' };

		ExecutionController.start(baseKey, ids);
		System.assertEquals(1, ExecutionController.getExecutionCount(baseKey + '_001000000000001AAA'));
		System.assertEquals(1, ExecutionController.getExecutionCount(baseKey + '_001000000000002AAA'));

		ExecutionController.start(baseKey, ids);
		System.assertEquals(2, ExecutionController.getExecutionCount(baseKey + '_001000000000001AAA'));

		ExecutionController.stop(baseKey, ids);
		System.assertEquals(1, ExecutionController.getExecutionCount(baseKey + '_001000000000001AAA'));

		ExecutionController.reset(baseKey, ids);
		System.assertEquals(0, ExecutionController.getExecutionCount(baseKey + '_001000000000001AAA'));
		System.assertEquals(0, ExecutionController.getExecutionCount(baseKey + '_001000000000002AAA'));
	}

	@IsTest
	static void testCanExecuteAndHasExecuted() {
		String key = 'KeyCheck';
		ExecutionController.reset(key);

		System.assertEquals(true, ExecutionController.canExecute(key));
		System.assertEquals(false, ExecutionController.hasExecuted(key));

		ExecutionController.start(key);
		System.assertEquals(false, ExecutionController.canExecute(key));
		System.assertEquals(true, ExecutionController.hasExecuted(key));
	}

	@IsTest
	static void testGetKeysAndLogStatus() {
		String key1 = 'K1';
		String key2 = 'K2';
		ExecutionController.clearAll();

		ExecutionController.start(key1);
		ExecutionController.start(key2);

		Set<String> keys = ExecutionController.getKeys();
		System.assert(keys.contains(key1));
		System.assert(keys.contains(key2));
		System.assertEquals(2, keys.size());

		Map<String, Integer> status = ExecutionController.logStatus();
		System.assertEquals(1, status.get(key1));
		System.assertEquals(1, status.get(key2));
	}

	@IsTest
	static void testBulkExecuteOnce() {
		String keyPrefix = 'BulkKey';
		Set<Id> ids = new Set<Id>{ '001000000000001AAA', '001000000000002AAA', '001000000000003AAA' };

		// Initially all true
		Set<Id> executed = ExecutionController.bulkExecuteOnce(keyPrefix, ids);
		System.assertEquals(ids.size(), executed.size());

		// Second time none should execute
		executed = ExecutionController.bulkExecuteOnce(keyPrefix, ids);
		System.assertEquals(0, executed.size());

		// Reset one key and try again
		ExecutionController.reset(keyPrefix + '_001000000000001AAA');
		Set<Id> singleIdSet = new Set<Id>{ '001000000000001AAA' };
		executed = ExecutionController.bulkExecuteOnce(keyPrefix, singleIdSet);
		System.assertEquals(1, executed.size());
		System.assert(executed.contains('001000000000001AAA'));
	}
}