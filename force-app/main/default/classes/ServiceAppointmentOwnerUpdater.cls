public without sharing class ServiceAppointmentOwnerUpdater {
    public class Request {
        @InvocableVariable(required = true)
        public Id serviceAppointmentId;

        @InvocableVariable(required = true)
        public Id ownerId;
    }

    public class Response {
        @InvocableVariable
        public String status;   // "OK" or "ERROR"

        @InvocableVariable
        public String message;  // Success or error details
    }

    @InvocableMethod(label = 'Update Service Appointment Owner'
                     description = 'Updates the OwnerId of a ServiceAppointment record.')
    public static List<Response> updateOwner(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request r : requests) {
            Response res = new Response();
            try {
                if (r == null || r.serviceAppointmentId == null || r.ownerId == null) {
                    res.status = 'ERROR';
                    res.message = 'Both serviceAppointmentId and ownerId are required.';
                } else {
                    ServiceAppointment sa = new ServiceAppointment(
                        Id = r.serviceAppointmentId,
                        OwnerId = r.ownerId
                    );
                    update sa;

                    res.status = 'OK';
                    res.message = 'Owner updated successfully.';
                }
            } catch (Exception e) {
                res.status = 'ERROR';
                res.message = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}