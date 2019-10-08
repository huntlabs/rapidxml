/*
 * Hunt - A xml library for D programming language.
 *
 * Copyright (C) 2018-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module rapidxml.rapidxml;

import std.stdio;
import std.exception;

import rapidxml.skip;

enum node_type
{
	node_document,      //!< A document node. Name and value are empty.
	node_element,       //!< An element node. Name contains element name. Value contains text of first data node.
	node_data,          //!< A data node. Name is empty. Value contains data text.
	node_cdata,         //!< A CDATA node. Name is empty. Value contains data text.
	node_comment,       //!< A comment node. Name is empty. Value contains comment text.
	node_declaration,   //!< A declaration node. Name and value are empty. Declaration parameters (version, encoding and standalone) are in node attributes.
	node_doctype,       //!< A DOCTYPE node. Name is empty. Value contains DOCTYPE text.
	node_pi,            //!< A PI node. Name contains target. Value contains instructions.
	node_literal        //!< Value is unencoded text (used for inserting pre-rendered XML).
}

class xml_base
{
	string m_name;
	string m_value;
	xml_node m_parent;

}

class xml_attribute :  xml_base
{
	xml_attribute m_prev_attribute;
	xml_attribute m_next_attribute;
	string	m_xmlns;
	string  m_local_name;

	xml_document document() 
	{
		if (xml_node node = m_parent)
		{
			while (node.m_parent)
				node = node.m_parent;
			return node.m_type == node_type.node_document ? cast(xml_document)(node) : null;
		}
		else
			return null;
	}

	string xmlns() 
	{
		if (m_xmlns) return m_xmlns;
		char[] p;
		char[] name = cast(char[])m_name.dup;
		for (p = name; p.length > 0 && p[0] != ':'; p=p[1..$])
		{	
			if ((m_name.length - p.length) >= m_name.length) 
				break;
		}
		if (p.length == 0 || ((m_name.length - p.length) >= m_name.length)) {
			m_xmlns = "nullstring";
			return m_xmlns;
		}
		xml_node  element = m_parent;
		if (element) 
		{
			char []xmlns = cast(char[])m_xmlns;
			element.xmlns_lookup(xmlns, name[0 .. m_name.length - p.length]);
			m_xmlns = cast(string)xmlns.dup;
		}
		return m_xmlns;
	}
}

class xml_node:  xml_base
{

	string m_prefix;
	string m_xmlns;
	node_type m_type;
	xml_node m_first_node;
	xml_node m_last_node;
	xml_attribute m_first_attribute;
	xml_attribute m_last_attribute;
	xml_node m_prev_sibling;
	xml_node m_next_sibling;
	string m_contents;

	string xmlns()
	{
		if(m_xmlns.length > 0)
			return m_xmlns;
		char[] xmlns;
		xmlns_lookup(xmlns , cast(char[])m_prefix);
		m_xmlns = cast(string)xmlns.dup;
		return m_xmlns;
	}

    xml_document document() 
    {
            xml_node node = cast(xml_node)(this);
            while (node.m_parent)
                node = node.m_parent;
            return node.m_type == node_type.node_document ? cast(xml_document)(node) : null;
		
    }

	void xmlns_lookup(ref char []xmlns,  char[]  prefix) 
	{
		char[] freeme;
		char[] attrname;
		int prefix_size = cast(int)prefix.length;
		if (prefix) {
			// Check if the prefix begins "xml".
			if (prefix_size >= 3
				&& prefix[0] == ('x')
				&& prefix[1] == ('m')
				&& prefix[2] == ('l')) {
				if (prefix_size == 3) {
					xmlns = cast(char[]) "http://www.w3.org/XML/1998/namespace";
					return;
				} else if (prefix_size == 5
							&& prefix[3] == ('n')
							&& prefix[4] == ('s')) {
					xmlns = cast(char[]) "http://www.w3.org/2000/xmlns/";
					return;
				}
			}

			attrname.length = prefix_size + 6;
			freeme = attrname;
			char[] p1= cast(char[])"xmlns";
			for(int i = 0 ;i < p1.length ; i++)
				attrname[i] = p1[i];

			char [] p = prefix;
			attrname[p1.length] = ':';
			int index = cast(int)p1.length + 1;
			while (p.length > 0) {
				attrname[index++] = p[0];
				p = p[1 .. $];
				if ((freeme.length - attrname[index .. $].length ) >= (prefix_size + 6)) break;
			}
			attrname = freeme;
		} else {
			attrname.length = 5;
			freeme = attrname ;
			char[]  p1=cast(char[])"xmlns";
			for(int i = 0 ;i < p1.length ; i++)
				attrname[i] = p1[i];
			attrname = freeme;
		}
		
		for ( xml_node node = this;
				node;
				node = node.m_parent) {
			xml_attribute attr = node.first_attribute(cast(string)attrname);
			if (attr !is null ) {
				xmlns = cast(char[])attr.m_value.dup;
				//  if (xmlns) {
				//      xmlns_size = attr->value_size();
				//  }
				break;
			}
		}
		if (xmlns.length == 0) {
			if (prefix.length == 0) {
				xmlns = cast(char[])"nullstring".dup;
				// xmlns_size = 0;
			}
		}
		
	}


	xml_node first_node(string name = null , string xmlns = null , bool case_sensitive = true)
	{
		if(xmlns.length == 0 && name.length > 0)
		{
			xmlns = this.xmlns();
		}

		for(xml_node child = m_first_node ; child ; child = child.m_next_sibling)
		{
			if((!name || child.m_name == name) && (!xmlns || child.xmlns() == xmlns))
			{				
				return child;
			}
		}

		return null;
	}

	xml_node last_node(string name = null , string xmlns = null , bool case_sensitive = true)
	{
		for(xml_node child = m_last_node ; child ; child = child.m_prev_sibling)
		{
			if((!name || child.m_name == name) && (!xmlns || child.xmlns() == xmlns))
				return child;
		}

		return null;
	}


	void prepend_node(xml_node child)
	{
		if(first_node())
		{
			child.m_next_sibling = m_first_node;
			m_first_node.m_prev_sibling = child;
		}
		else
		{
			child.m_next_sibling = null;
			m_last_node = child;
		}

		m_first_node = child;
		child.m_parent = this;
		child.m_prev_sibling = null;
	}

	void append_node(xml_node child)
	{
		if(first_node())
		{
			child.m_prev_sibling = m_last_node;
			m_last_node.m_next_sibling = child;
		}
		else
		{
			child.m_prev_sibling = null;
			m_first_node = child;
		}

		m_last_node = child;
		child.m_parent = this;
		child.m_next_sibling = null;
	}

	void insert_node(xml_node where , xml_node child)
	{
		if(where == m_first_node)
			prepend_node(child);
		else if(where is null)
			append_node(child);
		else
		{
			child.m_prev_sibling = where.m_prev_sibling;
			child.m_next_sibling = where;
			where.m_prev_sibling.m_next_sibling = child;
			where.m_prev_sibling = child;
			child.m_parent = this;
		}
	}

	void remove_first_node()
	{
		xml_node child = m_first_node;
		m_first_node = child.m_next_sibling;
		if(child.m_next_sibling)
			child.m_next_sibling.m_prev_sibling = null;
		else
			m_last_node = null;
		child.m_parent = null;
	}

	void remove_last_node()
	{
		xml_node child = m_last_node;
		if(child.m_prev_sibling)
		{
			m_last_node = child.m_prev_sibling;
			child.m_prev_sibling.m_next_sibling = null;
		}
		else
		{
			m_first_node = null;
		}

		child.m_parent = null;
	}



	void remove_node(xml_node where)
	{
		if(where == m_first_node)
			remove_first_node();
		else if(where == m_last_node)
			remove_last_node();
		else
		{
			where.m_prev_sibling.m_next_sibling = where.m_next_sibling;
			where.m_next_sibling.m_prev_sibling = where.m_prev_sibling;
			where.m_parent = null;
		}
	}

	void remove_all_nodes()
	{
		for( xml_node node = first_node(); node; node = node.m_next_sibling)
			node.m_parent = null;
		
		m_first_node = null;
	}


	xml_attribute first_attribute(string name = null , bool case_sensitive = true)
	{
		if(name)
		{
			for(xml_attribute attribute = m_first_attribute ; attribute ; attribute = attribute.m_next_attribute)
			{
			
				if(attribute.m_name == name)
				{	
					return attribute;
				}
			}

			return null;
		}
		else
		{
			return m_first_attribute;
		}
	}

	xml_attribute last_attribute(string name = null , bool case_sensitive = true)
	{
		if(name)
		{
			for(xml_attribute attribute = m_last_attribute ; attribute ; attribute = attribute.m_prev_attribute)
			{
				if(attribute.m_name == name)
					return attribute;
			}

			return null;
		}
		else
		{
			return m_last_attribute;
		}
	}

	void prepend_attribute(xml_attribute attribute)
	{
		if(first_attribute())
		{
			attribute.m_next_attribute = m_first_attribute;
			m_first_attribute.m_prev_attribute = attribute;
		}
		else
		{
			attribute.m_next_attribute = null;
			m_last_attribute = attribute;
		}
		m_first_attribute = attribute;
		attribute.m_parent = this;
		attribute.m_prev_attribute = null;
	}

	void append_attribute(xml_attribute attribute)
	{
		if(first_attribute())
		{
			attribute.m_prev_attribute = m_last_attribute;
			m_last_attribute.m_next_attribute = attribute;
		}
		else
		{
			attribute.m_prev_attribute = null;
			m_first_attribute = attribute;
		}

		m_last_attribute = attribute;
		attribute.m_parent = this;
		attribute.m_next_attribute = null;
	}

	void insert_attribute(xml_attribute where , xml_attribute attribute)
	{
		if(where == m_first_attribute)
			prepend_attribute(attribute);
		else if(where is null)
			append_attribute(attribute);
		else
		{
			attribute.m_prev_attribute = where.m_prev_attribute;
			attribute.m_next_attribute = where;
			where.m_prev_attribute.m_next_attribute = attribute;
			where.m_prev_attribute = attribute;
			attribute.m_parent = this;
		}
	}

	void remove_first_attribute()
	{
		xml_attribute attribute = m_first_attribute;
		if(attribute.m_next_attribute)
		{
			attribute.m_next_attribute.m_prev_attribute = null;
		}
		else
		{
			m_last_attribute = null;
		}

		attribute.m_parent = null;
		m_first_attribute = attribute.m_next_attribute;
	}

	void remove_last_attribute()
	{
		xml_attribute attribute = m_last_attribute;
		if(attribute.m_prev_attribute)
		{
			attribute.m_prev_attribute.m_next_attribute = null;
			m_last_attribute = attribute.m_prev_attribute;
		}
		else
			m_first_attribute = null;

		attribute.m_parent = null;
	}

	void remove_attribute(xml_attribute where)
	{
		if(where == m_first_attribute)
			remove_first_attribute();
		else if(where == m_last_attribute)
			remove_last_attribute();
		else
		{
			where.m_prev_attribute.m_next_attribute = where.m_next_attribute;
			where.m_next_attribute.m_prev_attribute = where.m_prev_attribute;
			where.m_parent = null;
		}
	}

	void remove_all_attributes()
	{
		for(xml_attribute attribute = first_attribute() ; attribute ; attribute = attribute.m_next_attribute)
		{
			attribute.m_parent = null;
		}
		m_first_attribute = null;
	}

	bool validate()
	{
		if(this.xmlns() == null)
		{	
			writeln("Element XMLNS unbound");
			return false;
		}
		for(xml_node child = first_node(); child ; child = child.m_next_sibling)
		{
			if(!child.validate())
				return false;
		}
		for(xml_attribute attribute = first_attribute() ; attribute ; attribute = attribute.m_next_attribute)
		{
			if(attribute.xmlns() == null)
			{	
				writeln("Attribute XMLNS unbound");
				return false;
			}
			for(xml_attribute otherattr = first_attribute() ; otherattr != attribute; otherattr = otherattr.m_next_attribute)
			{	
				if(attribute.m_name == otherattr.m_name)
				{	
					writeln("Attribute doubled");
					return false;
				}
				if(attribute.xmlns() == otherattr.xmlns() && attribute.m_local_name == otherattr.m_local_name)
				{
					writeln("Attribute XMLNS doubled");
					return false;
				}
			}

		}
		return true;
	}
}

class xml_document : xml_node
{
	string parse(int Flags)(string stext , xml_document parent = null)
	{
		this.remove_all_nodes();
		this.remove_all_attributes();
		this.m_parent = parent ? parent.m_first_node : null;
		char[] text = cast(char[])stext.dup;

		parse_bom(text);
		
		size_t index = 0;
		size_t length = text.length;
		while(1)
		{
			skip!(whitespace_pred)(text); 
			if(index >= text.length)
				break;
			if(text[index] =='<')
			{
				++index;
				text = text[index .. $];
				xml_node  node = parse_node!(Flags)(text);
				if(node)
				{
					this.append_node(node);
					if(Flags & (parse_open_only | parse_parse_one))
					{
						if(node.m_type == node_type.node_comment)
							break;
					}
				}
			}
			else
				throw new parse_error("expected <", text);
		}

		if(!first_node())
			throw new parse_error("no root element", text[index .. $ ]);

		return string.init;
	}

	xml_node parse_node(int Flags)(ref char[] text)
	{
		switch(text[0])
		{
			default:
				return parse_element!Flags(text);
			
			case '?':
				text = text[1 .. $ ];
				if(
					((text[0] == 'x' ) || (text[0] == 'X')) &&
				((text[0] == 'm' ) || (text[0] == 'M')) &&
				((text[0] == 'l' ) || (text[0] == 'L')) &&
				whitespace_pred.test(text[3]))
				{
					text = text[4 .. $];
					return parse_xml_declaration!Flags(text);
				}
				else
				{
					return parse_pi!Flags(text);
				}
			
			case '!':
				switch(text[1])
				{
				case '-':
					if(text[2] == '-')
					{
						text = text[3 .. $ ];
						return parse_comment!Flags(text);
					} 
					break;
				case ('['):
                    if (text[2] == ('C') && text[3] == ('D') && text[4] == ('A') &&
                        text[5] == ('T') && text[6] == ('A') && text[7] == ('['))
                    {
                        // '<![CDATA[' - cdata
                        text = text[8 .. $ ];     // Skip '![CDATA['
                        return parse_cdata!Flags(text);
                    }
                    break;

                // <!D
                case ('D'):
                    if (text[2] == ('O') && text[3] == ('C') && text[4] == ('T') &&
                        text[5] == ('Y') && text[6] == ('P') && text[7] == ('E') &&
                        whitespace_pred.test(text[8]))
                    {
                        // '<!DOCTYPE ' - doctype
                        text = text[9 .. $ ];      // skip '!DOCTYPE '
                        return parse_doctype!Flags(text);
                    }
					break;
				default:
					break;

				} 

				 text = text[1 .. $ ];     // Skip !
                while (text[0] != ('>'))
                {
                    if (text == null)
                        throw new parse_error("unexpected end of data", text);
                    text = text[1 .. $ ];
                }
                text = text[1 .. $ ];     // Skip '>'
                return null;   // No node recognized

		}
	}

	
	xml_node parse_cdata(int Flags)(ref char[] text)
	{
		// If CDATA is disabled
		if (Flags & parse_no_data_nodes)
		{
			// Skip until end of cdata
			while (text[0] != ']' || text[1] != ']' || text[2] != '>')
			{
				if (!text[0])
					throw new parse_error("unexpected end of data", text);
				text = text[1 .. $];
			}
			text = text[3 .. $];      // Skip ]]>
			return null;       // Do not produce CDATA node
		}

		// Skip until end of cdata
		char[] value = text;
		while (text[0] != (']') || text[1] != (']') || text[2] != ('>'))
		{
			if (!text[0])
				throw new parse_error("unexpected end of data", text);
			text = text[1 .. $ ];
		}

		// Create new cdata node
		xml_node cdata = new xml_node;
		xml_node.m_type = node_type.node_cdata;
		cdata.m_value = cast(string)value[ 0 .. value.length - text.length].dup;

		// Place zero terminator after value
		

		text = text[3 .. $ ];      // Skip ]]>
		return cdata;
	}
	
	char parse_and_append_data(int Flags)(xml_node node, ref char []text, char[] contents_start)
	{
		// Backup to contents start if whitespace trimming is disabled
		if (!(Flags & parse_trim_whitespace))
			text = contents_start;

		// Skip until end of data
		char [] value = text;
		char []end;
		if (Flags & parse_normalize_whitespace)
			end = skip_and_expand_character_refs!(text_pred, text_pure_with_ws_pred, Flags)(text);
		else
			end = skip_and_expand_character_refs!(text_pred, text_pure_no_ws_pred, Flags)(text);

		// Trim trailing whitespace if flag is set; leading was already trimmed by whitespace skip after >
		if (Flags & parse_trim_whitespace)
		{
			if (Flags & parse_normalize_whitespace)
			{
				// Whitespace is already condensed to single space characters by skipping function, so just trim 1 char off the end
				if (end[-1] == ' ')
					end = end[-1 .. $];
			}
			else
			{
				// Backup until non-whitespace character is found
				while (whitespace_pred.test(end[-1]))
					end = end[-1 .. $ - 1];
			}
		}

		// If characters are still left between end and value (this test is only necessary if normalization is enabled)
		// Create new data node
		if (!(Flags & parse_no_data_nodes))
		{
			xml_node data = new xml_node;
			data.m_value = cast(string)value[0 .. value.length - end.length].dup;
			node.append_node(data);
		}

		// Add data to parent node if no data exists yet
		if (!(Flags & parse_no_element_values))
			if (node.m_value.length == 0)
				node.m_value = cast(string)value[0 ..value.length - end.length];

		// Place zero terminator after value
		if (!(Flags & parse_no_string_terminators))
		{
			ubyte ch = text[0];
			end[0] ='\0';
			return ch;      // Return character that ends data; this is required because zero terminator overwritten it
		}
		else
		// Return character that ends data
		return text[0];
	}

	xml_node parse_element(int Flags)(ref char[] text)
	{
		xml_node element = new xml_node();
		char[] prefix = text;
		//skip element_name_pred
		skip!(element_name_pred)(text);
		if(text == prefix)
			throw new parse_error("expected element name or prefix", text);
		if(text.length >0 && text[0] == ':')
		{
			element.m_prefix = prefix[0 .. prefix.length - text.length].dup;
			text = text[1 .. $ ];
			char[] name = text;
			//skip node_name_pred
			skip!(node_name_pred)(text);
			if(text == name)
				throw new parse_error("expected element local name", text);
			element.m_name = name[0 .. name.length - text.length].dup;
		}
		else{
			element.m_name = prefix[ 0 .. prefix.length - text.length].dup;			
		}

		//skip whitespace_pred
		skip!(whitespace_pred)(text);
		parse_node_attributes!(Flags)(text , element);
		if(text.length > 0 && text[0] == '>')
		{
			text = text[1 .. $];
			char[] contents = text;
			char[] contents_end = null;
			if(!(Flags & parse_open_only))
			{	
				contents_end = parse_node_contents!(Flags)(text , element);
			}
			if(contents_end.length != contents.length )
			{
				element.m_contents = cast(string)contents[0 .. contents.length - contents_end.length].dup;
			}
		}
		else if(text.length > 0 && text[0] == '/')
		{
			text = text[1 .. $ ];
			if(text[0] != '>')
				throw new parse_error("expected >", text);
			
			text = text[1 .. $ ];

			if(Flags & parse_open_only)
				throw new parse_error("open_only, but closed", text);
		}
		else 
			throw new parse_error("expected >", text);
		// Place zero terminator after name 
		// no need.
		return element;
	}

	char[] parse_node_contents(int Flags)(ref char[] text , xml_node node)
	{
		char[] retval;
		
		while(1)
		{
			char[] contents_start = text;
			skip!(whitespace_pred)(text);
			char next_char = text[0];

			after_data_node:

			switch(next_char)
			{
				case '<':
				if(text[1] == '/')
				{
					retval = text;
					text = text[2 .. $ ];
					if(Flags & parse_validate_closing_tags)
					{
						string closing_name = cast(string)text.dup;
						skip!(node_name_pred)(text);
						if(closing_name == node.m_name)
							throw new parse_error("invalid closing tag name", text);
					}
					else
					{
						skip!(node_name_pred)(text);
					}

					skip!(whitespace_pred)(text);
					if(text[0] != '>')
						throw new parse_error("expected >", text);
					text = text[1 .. $];
					if(Flags & parse_open_only)
						throw new parse_error("Unclosed element actually closed.", text);
					
					return retval;
				}
				else
				{
					text = text[1 .. $ ];
					if(xml_node child = parse_node!(Flags & ~parse_open_only)(text))
						node.append_node(child);
				}
				break;
			default:
			 	next_char = parse_and_append_data!(Flags)(node, text, contents_start);
                goto after_data_node;   // Bypass regular processing after data nodes
			}
		}

		return null;
	}

	void parse_node_attributes(int Flags)(ref char[] text , xml_node node)
	{
		int index = 0;
		
		while(text.length > 0 && attribute_name_pred.test(text[0]))
		{
			char[] name = text;
			text = text[1 .. $ ];
			skip!(attribute_name_pred)(text);
			if(text == name)
				throw new parse_error("expected attribute name", name);

			xml_attribute attribute = new xml_attribute();
			attribute.m_name = cast(string)name[0 .. name.length - text.length].dup;
			
			node.append_attribute(attribute);

			skip!(whitespace_pred)(text);
			
			if(text.length ==0 || text[0] != '=')
				throw new parse_error("expected =", text);
			
			text = text[1 .. $ ];

			skip!(whitespace_pred)(text);
			
			char quote = text[0];
			if(quote != '\'' && quote != '"')
				throw new parse_error("expected ' or \"", text);
			
			
			text = text[1 .. $ ];
			char[] value = text ;
			char[] end;
			const int AttFlags = Flags & ~parse_normalize_whitespace;

			if(quote == '\'')
				end = skip_and_expand_character_refs!(attribute_value_pred!'\'' , attribute_value_pure_pred!('\'') , AttFlags)(text);
			else
				end = skip_and_expand_character_refs!(attribute_value_pred!('"') , attribute_value_pure_pred!('"') , AttFlags)(text);
			

			attribute.m_value = cast(string)value[0 .. value.length - end.length].dup;
			

			if(text.length > 0 && text[0] != quote)
				throw new parse_error("expected ' or \"", text);
			
			text = text[1 .. $ ];

			skip!(whitespace_pred)(text);
		}
	}

	static void skip(T )(ref char[] text)
	{
		
		char[] tmp = text;
		while(tmp.length > 0 && T.test(tmp[0]))
		{
			tmp = tmp[1 .. $];	
		}
		text = tmp;
	}

	void parse_bom(ref char[] text)
	{
		if(text[0] == 0xEF 
		&& text[1] == 0xBB 
		&& text[2] == 0xBF)
		{
			text = text[3 .. $ ];
		}
	}


	xml_node parse_xml_declaration(int Flags)(ref char[] text)
	{
		// If parsing of declaration is disabled
		if (!(Flags & parse_declaration_node))
		{
			// Skip until end of declaration
			while (text[0] != '?' || text[1] != '>')
			{
				if (!text[0]) 
				throw new parse_error("unexpected end of data", text);
				text = text[1 .. $ ];
			}
			text = text[2 .. $ ];    // Skip '?>'
			return null;
		}

		static if (Flags != 0)
		// Create declaration
		{
			xml_node declaration = new xml_node;
			declaration.m_type = node_type.node_declaration;



			// Skip whitespace before attributes or ?>
			skip!whitespace_pred(text);
			// Parse declaration attributes
			parse_node_attributes!Flags(text, declaration);

			// Skip ?>
			if (text[0] != '?' || text[1] != '>') 
				throw new parse_error("expected ?>", text);
			text = text[2 .. $ ];

			return declaration;
		}
	}

	
	xml_node parse_pi(int Flags)(ref char[] text)
	{
		// If creation of PI nodes is enabled
		if (Flags & parse_pi_nodes)
		{
			// Create pi node
			xml_node pi = new xml_node;
			xml_node.m_type = node_type.node_pi;

			// Extract PI target name
			char[] name = text;
			skip!node_name_pred(text);
			if (text == name) 
				throw new parse_error("expected PI target", text);
			pi.m_name = cast(string)name[0 .. name.length - text.length].dup;

			// Skip whitespace between pi target and pi
			skip!whitespace_pred(text);

			// Remember start of pi
			char[] value = text;

			// Skip to '?>'
			while (text[0] != '?' || text[1] != '>')
			{
				if (text == null)
					throw new parse_error("unexpected end of data", text);
				text = text[1 .. $ ];
			}

			// Set pi value (verbatim, no entity expansion or whitespace normalization)
			pi.m_value = cast(string)value[ 0 .. value.length - text.length ].dup;

			// Place zero terminator after name and value
			// no need

			text = text[2 .. $ ];                          // Skip '?>'
			return pi;
		}
		else
		{
			// Skip to '?>'
			while (text[0] != '?' || text[1] != '>')
			{
				if (text[0] == '\0')
					throw new parse_error("unexpected end of data", text);
				text = text[1 .. $ ];
			}
			text = text[2 .. $ ];    // Skip '?>'
			return null;
		}
	}


	xml_node parse_comment(int Flags)(ref char[] text)
	{
		// If parsing of comments is disabled
		if (!(Flags & parse_comment_nodes))
		{
			// Skip until end of comment
			while (text[0] != '-' || text[1] != '-' || text[2] != '>')
			{
				if (!text[0]) throw new parse_error("unexpected end of data", text);
				text = text[1 .. $];
			}
			text = text [3 .. $];     // Skip '-->'
			return null;      // Do not produce comment node
		}

		// Remember value start

		static if (Flags != 0)
		{
			string value = text;

			// Skip until end of comment
			while (text[0] != '-' || text[1] != '-' || text[2] != '>')
			{
				if (!text[0]) throw new parse_error("unexpected end of data", text);
				text= text[1 .. $];
			}

			// Create comment node
			xml_node comment = new xml_node;
			comment.m_type = node_type.node_comment;
			comment.m_value = cast(string)value[0 .. value.length - text.length].dup;

			// Place zero terminator after comment value
			// no need

			text = text[3 .. $ ];     // Skip '-->'
			return comment;
		}
	}

	// Parse DOCTYPE
	
	xml_node parse_doctype(int Flags)(ref char[] text)
	{
		// Remember value start
		char[] value = text;

		// Skip to >
		while (text[0] != '>')
		{
			// Determine character type
			switch (text[0])
			{

			// If '[' encountered, scan for matching ending ']' using naive algorithm with depth
			// This works for all W3C test files except for 2 most wicked
			case ('['):
			{
				text = text[1 .. $ ];     // Skip '['
				int depth = 1;
				while (depth > 0)
				{
					switch (text[0])
					{
						case '[': ++depth; break;
						case ']': --depth; break;
						default : throw new parse_error("unexpected end of data", text);
					}
					text = text[1 .. $];
				}
				break;
			}

			// Error on end of text
			case '\0':
				throw new parse_error("unexpected end of data", text);

			// Other character, skip it
			default:
				text = text[1 .. $ ];

			}
		}

		// If DOCTYPE nodes enabled
		if (Flags & parse_doctype_node)
		{
			// Create a new doctype node
			xml_node doctype = new xml_node;
			doctype.m_type = node_type.node_doctype;
			doctype.m_value = cast(string)value[ 0 .. value.length - text.length].dup;

			// Place zero terminator after value
			// no need

			text = text[1 .. $ ];      // skip '>'
			return doctype;
		}
		else
		{
			text = text[1 .. $ ];      // skip '>'
			return null;
		}
	}
}
