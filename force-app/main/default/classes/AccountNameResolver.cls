public without sharing class AccountNameResolver {
    /**
     * Recebe uma lista de nomes de Account e retorna um mapa (Name -> Id) para as contas encontradas.
     * Uso: chamar antes de invocar métodos que esperam Account Ids.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Id>> resolveAccountNamesToIds(List<String> accountNames) {
        // Retorna todas as Ids correspondentes a cada Name (evita "colapso" quando há duplicatas)
        Map<String, List<Id>> result = new Map<String, List<Id>>();
        if (accountNames == null || accountNames.isEmpty()) return result;

        // Normaliza e filtra nulos
        Set<String> namesSet = new Set<String>();
        for (String n : accountNames) {
            if (n != null) {
                String t = n.trim();
                if (t.length() > 0) namesSet.add(t);
            }
        }

        if (namesSet.isEmpty()) return result;

        // Consulta Accounts por Name (match exato). Se houver múltiplas accounts com o mesmo Name,
        // adicionamos todas as Ids na lista correspondente.
        for (Account a : [SELECT Id, Name FROM Account WHERE Name IN :namesSet]) {
            if (!result.containsKey(a.Name)) result.put(a.Name, new List<Id>());
            result.get(a.Name).add(a.Id);
        }

        return result;
    }
}