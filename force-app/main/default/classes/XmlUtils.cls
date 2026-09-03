/**
 * @description Utility class for serializing Apex data structures (Map/JSON) into XML.
 * Uses recursion to handle nested structures and XmlStreamWriter to ensure well-formed XML.
 */
public class XmlUtils {

    // ------------------------------------------------------------------------
    // PUBLIC METHODS
    // ------------------------------------------------------------------------

    /**
     * @description Converts a JSON String into an XML document.
     * @param jsonString The input JSON string.
     * @param rootName The name of the XML root element (e.g., 'Document').
     * @return The generated XML string.
     */
    public static String jsonToXml(String jsonString, String rootName) {
        if (String.isBlank(jsonString)) {
            throw new CustomException('Input JSON is blank or null.');
        }

        if (String.isBlank(rootName)) {
            throw new CustomException('Provided rootName is blank or null.');
        }

        Map<String, Object> dataMap;
        try {
            // Deserialize JSON to an untyped Map<String, Object> structure
            dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        } catch (Exception e) {
            throw new CustomException('Provided JSON is invalid: ' + e.getMessage());
        }

        return mapToXml(dataMap, rootName);
    }

    /**
     * @description Convenience overload: Converts a JSON String into XML and
     * attempts to infer the root element when the top-level object has a single key.
     * If inference is not possible, falls back to using 'Root' as the root element.
     * @param jsonString The input JSON string.
     * @return The generated XML string.
     */
    public static String jsonToXml(String jsonString) {
        if (String.isBlank(jsonString)) {
            throw new CustomException('Input JSON is blank or null.');
        }

        Object deserialized;
        try {
            deserialized = JSON.deserializeUntyped(jsonString);
        } catch (Exception e) {
            throw new CustomException('Provided JSON is invalid: ' + e.getMessage());
        }

        if (!(deserialized instanceof Map<String, Object>)) {
            // Not an object — cannot infer a root element
            throw new CustomException('Top-level JSON is not an object; cannot infer root element.');
        }

        Map<String, Object> topMap = (Map<String, Object>) deserialized;
        if (topMap.size() == 1) {
            String firstKey = (String) topMap.keySet().iterator().next();
            Object firstVal = topMap.get(firstKey);

            XmlStreamWriter writer = new XmlStreamWriter();
            writer.writeStartElement(null, firstKey, null);

            if (firstVal instanceof Map<String, Object>) {
                writeMapContents((Map<String, Object>) firstVal, writer);
            } else if (firstVal instanceof List<Object>) {
                List<Object> items = (List<Object>) firstVal;
                String itemTag = getItemTagName(firstKey);
                for (Object item : items) {
                    if (item instanceof Map<String, Object>) {
                        writer.writeStartElement(null, itemTag, null);
                        writeMapContents((Map<String, Object>) item, writer);
                        writer.writeEndElement();
                    } else {
                        writer.writeStartElement(null, itemTag, null);
                        writer.writeCharacters(String.valueOf(item));
                        writer.writeEndElement();
                    }
                }
            } else {
                // If the single top-level key holds a primitive, write it as
                // the text content of the root element rather than adding
                // a nested <Value> child.
                writer.writeCharacters(String.valueOf(firstVal));
            }

            writer.writeEndElement();
            return writer.getXmlString();
        }

        // Fallback: no single top-level key to infer -> use generic Root
        return mapToXml(topMap, 'Root');
    }

    /**
     * @description Converts a Map<String, Object> into an XML document.
     * @param dataMap The input Map<String, Object> (multi-level structure).
     * @param rootName The name of the XML root element.
     * @return The generated XML string.
     */
    public static String mapToXml(Map<String, Object> dataMap, String rootName) {
        if (dataMap == null || dataMap.isEmpty()) {
            throw new CustomException('Input Map is null or empty.');
        }
        
        // Initialize the writer for safe XML construction
        XmlStreamWriter writer = new XmlStreamWriter();

        // Write the root element start tag
        writer.writeStartElement(null, rootName, null);

        // Call the recursive method to process the Map contents
        writeMapContents(dataMap, writer);
        
        // Close the root element tag
        writer.writeEndElement(); 

        return writer.getXmlString();
    }

    /**
     * @description Convenience overload: Converts a Map into XML and attempts to
     * infer the root element when the Map has a single key. If the Map has a
     * single key whose value is a Map, that value will be used as the contents
     * of the inferred root element.
     * @param dataMap The input Map<String, Object>.
     * @return The generated XML string.
     */
    public static String mapToXml(Map<String, Object> dataMap) {
        if (dataMap == null || dataMap.isEmpty()) {
            throw new CustomException('Input Map is null or empty.');
        }

        if (dataMap.size() == 1) {
            String firstKey = (String) dataMap.keySet().iterator().next();
            Object firstVal = dataMap.get(firstKey);

            XmlStreamWriter writer = new XmlStreamWriter();
            writer.writeStartElement(null, firstKey, null);

            if (firstVal instanceof Map<String, Object>) {
                writeMapContents((Map<String, Object>) firstVal, writer);
            } else if (firstVal instanceof List<Object>) {
                List<Object> items = (List<Object>) firstVal;
                String itemTag = getItemTagName(firstKey);
                for (Object item : items) {
                    if (item instanceof Map<String, Object>) {
                        writer.writeStartElement(null, itemTag, null);
                        writeMapContents((Map<String, Object>) item, writer);
                        writer.writeEndElement();
                    } else {
                        writer.writeStartElement(null, itemTag, null);
                        writer.writeCharacters(String.valueOf(item));
                        writer.writeEndElement();
                    }
                }
            } else {
                // If the single top-level key holds a primitive, write it as
                // the text content of the root element rather than adding
                // a nested <Value> child.
                writer.writeCharacters(String.valueOf(firstVal));
            }

            writer.writeEndElement();
            return writer.getXmlString();
        }

        // No single top-level key to infer -> use default 'Root'
        return mapToXml(dataMap, 'Root');
    }

    // ------------------------------------------------------------------------
    // PRIVATE RECURSIVE METHOD
    // ------------------------------------------------------------------------

    /**
     * @description Recursive method that iterates over the Map and writes the XML elements.
     * @param dataMap The Map to be processed.
     * @param writer The XmlStreamWriter instance.
     */
    private static void writeMapContents(Map<String, Object> dataMap, XmlStreamWriter writer) {
        if (dataMap == null) {
            return;
        }

        for (String key : dataMap.keySet()) {
            Object value = dataMap.get(key);

            // Basic sanitization: remove characters that are not alphanumeric, hyphen, or underscore
            String tagName = key.replaceAll('[^a-zA-Z0-9_\\-]', '');

            if (value == null) {
                // Case 1: Null Value -> Write an empty tag <tagName></tagName>
                writer.writeStartElement(null, tagName, null);
                writer.writeEndElement();
            } else if (value instanceof Map<String, Object>) {
                // Case 2: Nested Structure (Recursion)
                writer.writeStartElement(null, tagName, null);
                // Recursive call to process the sub-map
                writeMapContents((Map<String, Object>) value, writer);
                writer.writeEndElement();

            } else if (value instanceof List<Object>) {
                // Case 3: List of Elements (Arrays)
                List<Object> items = (List<Object>) value;

                // Open the parent list tag (e.g., <Products>)
                writer.writeStartElement(null, tagName, null);

                // Determine the tag name for each item (e.g., <ProductItem>)
                String itemTagName = getItemTagName(tagName);

                for (Object item : items) {
                    if (item instanceof Map<String, Object>) {
                        // List item is a nested object (Recursion)
                        writer.writeStartElement(null, itemTagName, null);
                        writeMapContents((Map<String, Object>) item, writer);
                        writer.writeEndElement();
                    } else {
                        // List item is a primitive value
                        writer.writeStartElement(null, itemTagName, null);
                        writer.writeCharacters(String.valueOf(item));
                        writer.writeEndElement();
                    }
                }
                writer.writeEndElement(); // Close the parent list tag

            } else {
                // Case 4: Primitive Type (String, Number, Boolean, etc.)
                // <tagName>value</tagName>
                writer.writeStartElement(null, tagName, null);
                writer.writeCharacters(String.valueOf(value));
                writer.writeEndElement();
            }
        }
    }
    
    /**
     * @description Basic logic to determine the tag name for an element within a list.
     * @param listName The plural name of the list (e.g., 'Products').
     * @return The item tag name (e.g., 'ProductItem').
     */
    private static String getItemTagName(String listName) {
        // Simple attempt to singularize by removing trailing 's'
        if (listName.endsWith('s') && listName.length() > 1) {
            return listName.substring(0, listName.length() - 1);
        }
        // Generic fallback (e.g., 'VendorsItem')
        return listName + 'Item'; 
    }
}