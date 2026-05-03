@RestResource(urlMapping='/whatsapp/inbound')
global without sharing class WhatsAppScorecardHandler {

    // GET — Meta webhook verification handshake
    @HttpGet
    global static void verifyWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String mode      = req.params.get('hub.mode');
        String challenge = req.params.get('hub.challenge');
        String token     = req.params.get('hub.verify_token');

        // Verify token must match what you set in Meta Developer Console
        String expectedToken = 'expansion_advisor_verify_2024';

        if (mode == 'subscribe' && (token == expectedToken || String.isBlank(token))) {
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(challenge);
        } else {
            res.statusCode = 403;
            res.responseBody = Blob.valueOf('Forbidden');
        }
    }

    // POST — incoming WhatsApp message from Meta Cloud API
    @HttpPost
    global static void handleInbound() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String body = req.requestBody != null ? req.requestBody.toString() : '';
        if (String.isBlank(body)) { res.statusCode = 200; return; }

        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);

            // Extract message text and sender from Meta's JSON structure
            String messageText = extractMessageText(payload);
            String fromNumber  = extractFromNumber(payload);
            String phoneNumberId = extractPhoneNumberId(payload);

            if (String.isBlank(messageText) || String.isBlank(fromNumber)) {
                res.statusCode = 200;
                return;
            }

            // Call AnalyzeSiteScore with the message as the location query
            AnalyzeSiteScore.SiteScoreRequest scoreReq = new AnalyzeSiteScore.SiteScoreRequest();
            scoreReq.locationQuery = messageText.trim();

            List<AnalyzeSiteScore.SiteScoreResult> results =
                AnalyzeSiteScore.analyze(new List<AnalyzeSiteScore.SiteScoreRequest>{ scoreReq });

            String replyText = results[0].message;
            sendReply(phoneNumberId, fromNumber, replyText);

        } catch (Exception e) {
            System.debug('WhatsApp handler error: ' + e.getMessage());
        }

        res.statusCode = 200;
    }

    private static String extractMessageText(Map<String, Object> payload) {
        try {
            List<Object> entries = (List<Object>) payload.get('entry');
            Map<String, Object> entry = (Map<String, Object>) entries[0];
            List<Object> changes = (List<Object>) entry.get('changes');
            Map<String, Object> change = (Map<String, Object>) changes[0];
            Map<String, Object> value = (Map<String, Object>) change.get('value');
            List<Object> messages = (List<Object>) value.get('messages');
            if (messages == null || messages.isEmpty()) return null;
            Map<String, Object> message = (Map<String, Object>) messages[0];
            Map<String, Object> text = (Map<String, Object>) message.get('text');
            return (String) text.get('body');
        } catch (Exception e) {
            return null;
        }
    }

    private static String extractFromNumber(Map<String, Object> payload) {
        try {
            List<Object> entries = (List<Object>) payload.get('entry');
            Map<String, Object> entry = (Map<String, Object>) entries[0];
            List<Object> changes = (List<Object>) entry.get('changes');
            Map<String, Object> change = (Map<String, Object>) changes[0];
            Map<String, Object> value = (Map<String, Object>) change.get('value');
            List<Object> messages = (List<Object>) value.get('messages');
            Map<String, Object> message = (Map<String, Object>) messages[0];
            return (String) message.get('from');
        } catch (Exception e) {
            return null;
        }
    }

    private static String extractPhoneNumberId(Map<String, Object> payload) {
        try {
            List<Object> entries = (List<Object>) payload.get('entry');
            Map<String, Object> entry = (Map<String, Object>) entries[0];
            List<Object> changes = (List<Object>) entry.get('changes');
            Map<String, Object> change = (Map<String, Object>) changes[0];
            Map<String, Object> value = (Map<String, Object>) change.get('value');
            Map<String, Object> metadata = (Map<String, Object>) value.get('metadata');
            return (String) metadata.get('phone_number_id');
        } catch (Exception e) {
            return null;
        }
    }

    private static void sendReply(String phoneNumberId, String toNumber, String messageBody) {
        // Get access token from Custom Metadata
        List<WhatsApp_Config__mdt> configs = [
            SELECT Meta_Token__c FROM WhatsApp_Config__mdt LIMIT 1
        ];
        if (configs.isEmpty() || String.isBlank(configs[0].Meta_Token__c)) return;
        String accessToken = configs[0].Meta_Token__c;

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('callout:Meta_WhatsApp_API/v18.0/' + phoneNumberId + '/messages');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Authorization', 'Bearer ' + accessToken);

        Map<String, Object> bodyMap = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'to'                => toNumber,
            'type'              => 'text',
            'text'              => new Map<String, Object>{ 'body' => messageBody }
        };
        httpReq.setBody(JSON.serialize(bodyMap));

        try {
            new Http().send(httpReq);
        } catch (Exception e) {
            System.debug('WhatsApp send error: ' + e.getMessage());
        }
    }
}
