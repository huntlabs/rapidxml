# rapidxml
A XML Parsing library for D Programming Language.

# Example

```D

import rapidxml;

import stdio;

void main()
{
    auto doc = new xml_document;
    
    string doc_text = "<single-element/>";
    
    doc.parse!(0)(doc_text);
    
    auto node = doc.first_node();
    
    writeln(node.m_name);
    
    doc.validate();
}
