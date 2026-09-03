global without sharing class md_reportDocumentDownloadWrapper {
  public class DocumentDownloadResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String  message;
    @AuraEnabled public String  pdfData;

    public DocumentDownloadResult() {
      this.success = false;
    }
  }

  public class PMC_DH_DocumentResponseWrapper {
    public ResponseData objData;
  }

  public class ResponseData {
    public String strStatusCode;
    public String strMessage;
    public String strData;
    public String strKey;
  }

  public class NfeXmlErrorResponse {
    public String message;
  }
}