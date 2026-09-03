/**
 * @description       :
 * @author            : Raphael Soares
 * @author username   : raphael.holanda.ext@iconit.com.br
 * @company           : Icon IT Solutions
 * @last modified on  : 23-11-2021
 * @last modified by  : raphael.holanda.ext@iconit.com.br
 **/
global class ExceptionUtils {
	global static String debug(Exception ex) {
		String response =
			'\nType: ' +
			ex.getTypeName() +
			'\nMessage: ' +
			ex.getMessage() +
			'\nException::: ' +
			Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') +
			'\nCause: ' +
			ex.getCause() +
			'\nStackTrace: ' +
			ex.getStackTraceString();
		System.debug(response);
		return response;
	}
}