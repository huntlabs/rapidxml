# rapidxml
A XML Parsing library for D Programming Language. Ported from C++ [rapidxml](http://rapidxml.sourceforge.net).

# Example

```D

import rapidxml;

import stdio;

void main()
{
    auto doc = new xml_document;

    string xml = "<single-element/>";

    doc.parse(xml);

    auto node = doc.first_node();

    writeln(node.m_name);

    doc.validate();
}
