import rapidxml;

import std.stdio;

void test1()
{
    xml_document doc = new xml_document;
    string doc_text = "<single-element/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    assert(node.m_name == "single-element");
    doc.validate();
}

void test2()
{   
    xml_document doc = new xml_document;
    string doc_text = "<pfx:single-element/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    assert(node.m_name == "single-element");
    doc.validate();
}

void test3()
{
    xml_document doc = new xml_document;
    string doc_text = "<single-element attr='one' attr=\"two\"/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    
    assert(node.m_name == "single-element");
    doc.validate();
}

void test4()
{
    xml_document doc = new xml_document;
    string doc_text = "<single-element pfx1:attr='one' attr=\"two\"/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    
    assert(node.m_name == "single-element");
    auto attr = node.first_attribute();
    assert(attr.xmlns() == null);
    doc.validate();

}

void test5()
{
    xml_document doc = new xml_document;
    string doc_text = "<single-element pfx1:attr='one' pfx2:attr=\"two\" xmlns:pfx1='urn:fish' xmlns:pfx2='urn:fish'/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    
    assert(node.m_name == "single-element");
    doc.validate();
}

void test6()
{
    xml_document doc = new xml_document;
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'/>";
    doc.parse!(0)(doc_text);
    auto node = doc.first_node();
    
    assert(node.m_name == "single");
    doc.validate();
}

void test7()
{
    xml_document doc = new xml_document;
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
    doc.parse!(0)(doc_text);

    auto node = doc.first_node();
    assert("single" == node.m_name);
    auto child = node.first_node(null, "urn:potato");
    
    assert(child);
    assert("child" == child.m_name);
    assert("urn:potato" == child.xmlns);
    
    child = node.first_node();
    assert("firstchild" == child.m_name);
    assert("urn:xmpp:example" == child.xmlns);
    //std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;

    child = node.first_node("child");
    assert("child" == child.m_name);
    assert("urn:xmpp:example" == child.xmlns);
    doc.validate();
}

void test8()
{
    xml_document doc = new xml_document;
        string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
        doc.parse!0(doc_text);

        auto node = doc.first_node();
        assert("single" == node.m_name);
        assert("urn:xmpp:example" == node.xmlns());
        auto child = node.first_node(null, "urn:potato");
        assert(child);
        assert("child" == child.m_name);
        assert("urn:potato" == child.xmlns());
        child = node.first_node();
        assert("firstchild" == child.m_name);
        assert("urn:xmpp:example" == child.xmlns());
        //std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;
        child = node.first_node("child");
        assert("child" == child.m_name);
        assert("urn:xmpp:example" == child.xmlns());
        //std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;
        doc.validate();
}

void test10()
{
    xml_document doc = new xml_document;
    string doc_text = "<pfx:class><student attr='11' attr2='22'><age>10</age><name>zhyc</name></student><student><age>11</age><name>spring</name></student></pfx:class>";
    doc.parse!(0)(doc_text);

    auto node = doc.first_node();
    assert(node.m_name == "class");
    auto student = node.first_node();
    auto attr = student.first_attribute();
    assert(attr.m_name == "attr");
    assert(attr.m_value == "11");
    

    auto attr2 = attr.m_next_attribute;
    assert(attr2.m_name=="attr2");
    assert(attr2.m_value == "22");

    assert(student.m_name == "student");
    
    
    auto age = student.first_node();
    assert(age.m_name == "age");
    assert(age.m_value == "10");
    auto name = age.m_next_sibling;
    assert(name.m_name == "name");
    assert(name.m_value == "zhyc");
    auto student1 = student.m_next_sibling;
    
    auto age1 = student1.first_node();
    assert(age1.m_name == "age");
    assert(age1.m_value == "11");
    auto name1 = age1.m_next_sibling;
    assert(name1.m_name == "name");
    assert(name1.m_value == "spring");
    
    assert(student1.m_next_sibling is null);

    doc.validate();
}

void test11()
{
    xml_document doc = new xml_document;
    string doc_text = "<pfx:class><student at";
    doc.parse!(0)(doc_text);
    
}

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
    test10();
    test11();

    return 0;
}
