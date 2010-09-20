import std.string;
import std.stdio;

 // ---------------------------------------------------

class MLTree
{
private:
    MLNode root;
    MLNode[] nodes;

    void parseTreeCont( char[] rawCont )
    {
        bool isText = false;
        bool ignore = false;
        char[] buf;
        char cChar;

        for( int pos = 0 ; pos < rawCont.length ; pos++ )
        {
            buf = "";
            ignore = false;

            while( pos < rawCont.length && rawCont[pos] != '<' )
            {
                if( nodes.length > 0 )
                    nodes[length-1].addText( rawCont[pos] );
                pos++;
            }

            if( (pos+4) < rawCont.length  && rawCont[ pos+1 .. pos+4 ] != "!--" ) // if not a comment block
            {
                if( ((pos+1) < rawCont.length) && rawCont[(pos+1)] == '!' )
                    ignore = true;

                for( ; (pos < rawCont.length) && (rawCont[pos] != '>' || isText) ; pos++ )
                {
                    if( rawCont[pos] == '\'' || rawCont[pos] == '"' )
                    {
                        if( !isText )
                        {
                            cChar = rawCont[pos];
                            isText = true;
                        }
                        else if( rawCont[pos] == cChar )
                        {
                            isText = false;
                        }
                    }

                    buf ~= rawCont[pos];
                }

                if( pos < rawCont.length ) //? Add > to the end
                    buf ~= rawCont[pos];

                if( !ignore )
                    nodes ~= new MLNode(buf);
            }
            else if( (pos+4) < rawCont.length ) // if is a comment block
            {
                // wind past comment
                while( (pos+3) < rawCont.length )
                {
                    if( rawCont[pos .. pos+3] != "-->" )
                        pos++;
                    else
                    {
                        pos += 2;
                        break;
                    }
                }
            }
        }
    }

    void arrangeTree()
    {
        MLNode*[] parentStack;

        parentStack ~= &root;

        for( uint i = 0 ; i < nodes.length ; i++ )
        {
            if( nodes[i].isEnding() && parentStack.length > 1 ) // if node is ending and not (invalidly) ending root node
                parentStack.length = parentStack.length - 1; // Pop ! - The following nodes no longer children of whats closed

            nodes[i].setParent( parentStack[length-1] ); // Set parent
            parentStack[$-1].addChild( &nodes[i] ); // Make Child of Parent

            if( !nodes[i].isParticle() && !nodes[i].isEnding() ) // If node isnt a paticle
                parentStack ~= &nodes[i]; // Push ! - Make parent of the following nodes
        }
    }

public:
    this( char[] rawCont = "" )
    {
        root = new MLNode();
        parseTreeCont( rawCont );
        arrangeTree();
    }

    MLNode* getRoot() { return &root; }

    MLNode getNodeWith( char[] pType = "", char[] pParmType = "", char[] pVal = "" )
    {
        MLNode retNode = root;

        foreach( MLNode node ; nodes )
        {
            if( pType == node.getType() )
            {
                if( pParmType == "" )
                {
                    retNode = node;
                    break;
                }

                if( node.hasParm(pParmType) )
                {
//                    if( icmp(pVal, node.getParm(pParmType)) >= 0 )
                    if( pVal == node.getParm(pParmType) )
                    {
                        retNode = node;
                        break;
                    }
                }
            }
        }

        return retNode;
    }

    bool hasNodeWith( char[] pType = "", char[] pParmType = "", char[] pVal = "" )
    {
        if( getNodeWith(pType,pParmType,pVal) == root )
            return false;
        return true;
    }

    char[] toString()
    {
        char[] retVar;
        foreach( MLNode node ; nodes )
        {
            retVar ~= node.toString();
        }
        return retVar;
    }
}

 //! ##################################################################################################

class MLNode
{
private:
    char[] type, text;
    char[][ char[] ] parms;
    bit particle = false;
    bit dummy = false;
    bit ending = false;

    int byteSize = 0;

    MLNode* parent;
    MLNode*[] children;

    void parseNodeCont( char[] rawNode )
    {
        int pos = 0;

        if( rawNode[1] == '/' )
            ending = true;

        if( rawNode[length-2] == '/' )
            particle = true;

        pos = ifind( rawNode, "=" );

        if( pos == -1 )
        { // if no '='-sign is found, assume its a blank tag ( 0 parms )
            if( ending )
                type = rawNode[2 .. (length-1)];
            else if( particle )
                type = rawNode[1 .. (length-2)];
            else
                type = rawNode[1 .. (length-1)];
            return;
        }

        pos = ifind( rawNode, " " );

        if( pos != -1 )
            type = rawNode[(1+ending) .. pos];

        bool isText = false;
        char[] parmType, parmVal;
        char cChar;

        while( pos < rawNode.length )
        {
            parmType = "";
            parmVal = "";

            while( pos < rawNode.length && rawNode[pos] == ' ' ) // Wind past whitespace
                pos++;

            if( rawNode[pos] == '>' || rawNode[pos .. $] == "/>" )
                break;

            for( ; pos < rawNode.length && rawNode[pos] != '=' ; pos++ )
                parmType ~= rawNode[pos];

            pos++;

            if( pos < rawNode.length && (rawNode[pos] == '\'' || rawNode[pos] == '"') )
            {
                cChar = rawNode[pos];
                pos++;
                for( ; pos < rawNode.length && rawNode[pos] != cChar ; pos++ )
                    parmVal ~= rawNode[pos];
            }

            parms[parmType] = parmVal;
            pos++;
        }
    }

public:
    this( char[] rawCont = "" )
    {
        if( rawCont != "" )
            parseNodeCont( rawCont );
        else
            dummy = true;
    }

    bool isDummy() { return dummy; }
    bool isParticle() { return particle; }
    bool isEnding() { return ending; }

    void setParent( MLNode* pParent ) { parent = pParent; }
    void addChild( MLNode* pChild ) { children ~= pChild; }

    MLNode* getParent() { return parent; }
    MLNode*[] getChildren() { return children; }

    MLNode getChildNo( uint no )
    {
        if( no < children.length )
            return *children[no];
        return *children[$-1];
    }

    MLNode getChildWith( char[] pType = "", char[] pParmType = "", char[] pVal = "" )
    {
        MLNode retNode = *children[0];

        foreach( MLNode* child ; children )
        {
            if( pType == child.getType() )
            {
                if( pParmType == "" )
                {
                    retNode = *child;
                    break;
                }

                if( child.hasParm(pParmType) )
                {
                    if( pVal == child.getParm(pParmType) )
                    {
                        retNode = *child;
                        break;
                    }
                }
            }
        }

        return retNode;
    }

    void addText( char addText )
    {
        text ~= addText;
    }

    char[] getText() { return text; }
    char[] getType() { return type; }

    char[] getParm( char[] pParmType )
    {
        if( ( pParmType in parms ) != null )
            return *( pParmType in parms );
        return "";
    }

    bool hasParm( char[] pParmType )
    {
        if( ( pParmType in parms ) != null )
            return true;
        return false;
    }

    char[] toString()
    {
        if( dummy ) return "";

        char[] ret;

        ret ~= "<";
        if( ending ) ret ~= "/";
        ret ~= type;

        foreach( char[] parKey, char[] parCont ; parms )
            ret ~= " " ~ parKey ~ "=\"" ~ parCont ~ "\"";

        if( particle ) ret ~= "/";
        ret ~= ">";
        ret ~= text;

        return ret;
    }
}
