//=============================================================================
// Shui's Script Library v0.64, Part 01
// Copy the necessary functions to your scripts to use them.
//-----------------------------------------------------------------------------
// Copyright (c) 2012-2020, Shuichi Shinji
// Contains script examples from the LSL Wiki (c) the appropriate authors.
// See also http://wiki.secondlife.com/wiki/Combined_Library
// and http://wiki.secondlife.com/wiki/UTF-8.
// All rights reserved.
//-----------------------------------------------------------------------------
// Changelog:
// - v0.47 ... Initial release version
// - v0.48 ... Added shuiShowDialog
// - v0.49 ... Added shuiIsMonoVM and some optimizations
// - v0.50 ... Added shuiGetChannelFor2, shuiGetOrd*, shuiGetChr*
// - v0.51 ... Added shuiPrintString
// - v0.52 ... Fixed bug in shuiRoundFloat
// - v0.53 ... Avination compatibility
// - v0.54 ... Fixed shuiOrd7, shuiIsVector and shuiIsRotation
// - v0.55 ... Fixed shuiIsVector and shuiIsRotation again, added shuiNormRot,
//             shuiScaleRot, shuiConstrainRotToPlane, shuiInterpolateRot,
//             shuiGetPosInFrontOf
// - v0.56 ... Fixed order in shuiGetInventoryList
// - v0.57 ... Added shuiGetStringBytes, date functions independent, test rework
// - v0.58 ... Fixed shuiGetFirstName for leading spaces, added shuiFindMatch
// - v0.59 ... Changed shuiRoundFloat, added many new functions, split library
// - v0.60 ... Added shuiCompressKey and shuiDecompressKey
// - v0.61 ... Added shuiInteger2Hex, shuiFloat2Hex, shuiIsBase64,
//             shuiGetDayOfWeek, shuiGetDayOfWeekTS, shuiGetDayOfMonthTS
// - v0.62 ... Added shuiIsOwner, OpenSim compatibility for shuiCompressKey
// - v0.63 ... Added shuiGetPrimFace
// - v0.64 ... Added shuiPrintList and shuiShowMenu
//-----------------------------------------------------------------------------
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// - Standalone redistribution in parts or as whole is not permitted, it may
//   only be sold as part of your own products, either copy or transfer only.
//-----------------------------------------------------------------------------
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//=============================================================================

string SHUI_ASCII_TABLE = "☺☻♥♦♣♠•◘○◙♂♀♪♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ";
//"

// Compares two strings and returns 0 if they are equal,
// -1 if s1 is lower or 1 if s1 is greater than s2.
integer shuiStrCompare ( string s1, string s2 )  // by Xaviar Czervik, modified by Shuichi Shinji
{
    if ( s1 == s2 ) return 0;
    if ( s1 == llList2String( llListSort( [s1, s2], 1, TRUE ), 0 ) ) return -1;
    return 1;  // in LSO, a simple comparison maps to strcmp, but not in Mono
}

// Replaces all occurences of <replace> in <str> by <by>.
// Implemented with llParseStringKeepNulls.
string shuiStrReplace ( string str, string replace, string by )
{
    return llDumpList2String( llParseStringKeepNulls( str, [replace], [] ), by );
}

// Replaces all occurences of <replace> in <str> by <by>.
// Implemented without llParseStringKeepNulls.
string shuiStrReplace2 ( string str, string replace, string by )
{
    integer pos = -1;
    integer len = llStringLength( replace );
    while ( ~(pos = llSubStringIndex( str, replace )) )
    {
        string str1 = "";
        string str2 = "";
        if ( pos > 0 ) str1 = llGetSubString( str, 0, pos-1 );
        if ( llStringLength(str) > pos+len ) str2 = llGetSubString( str, pos+len, -1 );
        str = str1 + by + str2;
    }
    return str;
}

// Returns a substring in <msg> that is enclosed by <start> and <end>.
// Suitable e.g. to parse simple XML data.
string shuiFindMatch ( string msg, string start, string end )
{
    integer idx = llSubStringIndex( msg, start ); 
    if ( ~idx )
    {
        msg = llGetSubString( msg, idx + llStringLength( start ), -1 );
        if ( ~(idx = llSubStringIndex( msg, end )) ) return llGetSubString( msg, 0, idx - 1 );
    }
    return "";
}

// Works just like llParseString2List and llParseStringKeepNulls.
// Instead of each list being limited to 8 items, it supports 1024.
// The maximum length of src is 2,097,151 characters.
list shuiParseString2List ( string src, list separators, list spacers, integer keepNulls )  // by Strife Onizuka
{
    integer i = ~(separators != []);
    integer r =  (spacers    != []);
    spacers  += separators;
    list out  = "" + (separators = []);
    string p;
    integer offset;
    while ( (i = -~i) < r )
        if ( !~llListFindList( out, (list)(p = llList2String( spacers, i )) ) )
            if ( ~(offset = llSubStringIndex( src, p )) )
            {
                separators += ((offset + 0xFFF00000) << 11) | (i + 0x400);
                out += p;
            }
    out = [];
    offset = 0xFFF00000;
    while ( separators != [] )  // can't use just "while(separators)" because of JIRA:SVC-689
    {
        if ( offset <= (i = ( (r = llList2Integer( separators = llListSort( separators, 1, TRUE ), 0 )) >> 11)) )
        {
            if ( offset ^ i || keepNulls ) out += llDeleteSubString( src, i - offset, -1 );
            src = llDeleteSubString( src, 0, ~(offset - (i += llStringLength( p = llList2String( spacers, (r & 0x7FF) - 0x400 ) ))) );
            if ( r & 0x400 ) out += p;
            offset = i;
        }
        separators = llDeleteSubList( separators, 0, 0 );
        if ( ~(i = llSubStringIndex( src, p )) ) separators += ((i + offset) << 11) | (r & 0x7FF);
    }
    if ( src != "" || keepNulls ) out += src;
    return out;
}

// Deep voodoo base 4096 key compression.
// It produces fixed length encodings of 11 characters from a key.
// Copyright (C) 2009 Adam Wozniak and Doran Zemlja, improved by Kitty Sarrasine.
// Released into the public domain. Free for anyone to use for any purpose they like.
string shuiCompressKey ( key k )
{
    string s = llToLower( shuiStrReplace( k, "-", "" ) + "0" );
    string ret; integer i = 0;
    string a; string b; string c; string d;
    while ( i < 32 )
    {
        a = llGetSubString( s, i, i ); i++;
        b = llGetSubString( s, i, i ); i++;
        c = llGetSubString( s, i, i ); i++;
        d = "b";
             if ( a == "0" ) { a = "e"; d = "8"; }
        else if ( a == "d" ) { a = "e"; d = "9"; }
        else if ( a == "f" ) { a = "e"; d = "a"; }
        ret += "%e" + a + "%" + d + b + "%b" + c;
    }
    return llUnescapeURL( ret );
}
 
// Deep voodoo base 4096 key decompression.
// It decompresses fixed length encodings of 11 characters back into a key.
// Copyright (C) 2009 Adam Wozniak and Doran Zemlja.
// Released into the public domain. Free for anyone to use for any purpose they like.
key shuiDecompressKey ( string s )
{
   string ret; integer i;
   string a; string b; string c; string d;
   s = llToLower( llEscapeURL( s ) );
   for ( i = 0; i < 99; i += 9 )
   {
      a = llGetSubString( s, i + 2, i + 2 );
      b = llGetSubString( s, i + 5, i + 5 );
      c = llGetSubString( s, i + 8, i + 8 );
      d = llGetSubString( s, i + 4, i + 4 );
           if ( d == "8" ) a = "0";
      else if ( d == "9" ) a = "d";
      else if ( d == "a" ) a = "f";
      ret = ret + a + b + c;
   }
   return llGetSubString( ret,  0,  7 ) + "-" + llGetSubString( ret,  8, 11 ) + "-" +
          llGetSubString( ret, 12, 15 ) + "-" + llGetSubString( ret, 16, 19 ) + "-" +
          llGetSubString( ret, 20, 31 );
}

// Print a long string in several parts of up to "max" length (max. 1024 bytes). It's split
// at line breaks and each part is printed without timestamps and object name for easier
// copy & paste into notecards. Note: Non-ASCII characters take more than one byte (2-4).
shuiPrintString ( string str, integer max )
{
    list    lines = llParseStringKeepNulls( str, ["\n"], [] );
    integer num   = llGetListLength( lines );
    integer idx   = 0;
    while ( idx < num )
    {
        string out = "";
        string nex = "";
        // if first line was too long, we would get an endless loop, so check for empty string
        while ( idx < num && (llStringLength( (nex = out + "\n" + llList2String( lines, idx )) ) < max || out == "") ) { out = nex; ++idx; }
        if ( out ) llOwnerSay( out );  // print old string that is not too long
    }
}

// Print a list consisting of multiple lines in several parts of up to "max" length
// (max. 1024 bytes). Each part is printed without timestamps and object name for easier
// copy & paste into notecards. Note: Non-ASCII characters take more than one byte (2-4).
shuiPrintList ( list lines, integer max )
{
    integer num = llGetListLength( lines );
    integer idx = 0;
    while ( idx < num )
    {
        string out = "";
        string nex = "";
        // if first line was too long, we would get an endless loop, so check for empty string
        while ( idx < num && (llStringLength( (nex = out + "\n" + llList2String( lines, idx )) ) < max || out == "") ) { out = nex; ++idx; }
        if ( out ) llOwnerSay( out );  // print old string that is not too long
    }
}

// Returns length of string in bytes.
integer shuiGetStringBytes ( string msg )
{
    return (llStringLength( (string)llParseString2List( llStringToBase64( msg ), ["="], [] ) ) * 3) >> 2;
}

// Returns the 7 bit ASCII code (actually, only 0-126 ASCII printable chars)
// for character c.
integer shuiOrd7 ( string c )
{
    if ( c == "" ) return 0;
    return llBase64ToInteger( llStringToBase64(c) ) >> 24;
}

// Returns the 8 bit ASCII code (using IBM Codepage 437) for character c.
// For non-ASCII characters, 0 is returned.
integer shuiOrd8 ( string c )
{
    if ( c == "" ) return 0;
    return llSubStringIndex( SHUI_ASCII_TABLE, c ) + 1;  // starts with char 1, returns -1+1 for char 0
}

// Returns character for 7 bit ASCII code (only 0-126 ASCII printable chars).
string shuiChr7 ( integer i )
{
    return llGetSubString( llBase64ToString( llIntegerToBase64(i) ), 3, 3 );  // 0-126 ASCII printable chars only
}

// Returns character for 8 bit ASCII code (using IBM Codepage 437).
// For invalid ASCII codes, an empty string is returned.
string shuiChr8 ( integer i )
{
    if ( i < 1 ) return "";
    return llGetSubString( SHUI_ASCII_TABLE, i - 1, i - 1 );
}

// Convert the given integer to hexadecimal notation.
// Does not use the sign bit, but treats the input as an unsigned int.
string shuiInteger2Hex ( integer input )
{
    string hex;
    do hex = llGetSubString( "0123456789abcdef", input & 0x0f, input & 0x0f ) + hex;
    while ( input = (0x0fffffff & (input >> 4)) );
    return "0x" + hex;
}

// Encode the given float in hexadecimal notation with minimal overhead and without errors.
// Decode by simply casting to (float).
// Copyright Strife Onizuka, 2006-2007, LGPL, http://www.gnu.org/copyleft/lesser.html or (cc-by) http://creativecommons.org/licenses/by/3.0/
// http://wiki.secondlife.com/wiki/Float2Hex
string shuiFloat2Hex ( float input )
{
    string hexc = "0123456789abcdef";
    if ( input != (integer)input )  // LL screwed up hex integers support in rotation & vector string typecasting
    {
        string str = (string)input;
        if ( !~llSubStringIndex( str, "." ) ) return str;  // NaN and Infinities
        float   unsigned = llFabs( input );  // logs don't work on negatives
        integer exponent = llFloor( (llLog( unsigned ) / 0.69314718055994530941723212145818) );  // floor(log2(b)) + rounding error
        integer mantissa = (integer)((unsigned / (float)("0x1p" + (string)(exponent -= ((exponent >> 31) | 1)))) * 0x4000000);  // shift up into integer range
        integer index    = (integer)(llLog( mantissa & -mantissa ) / 0.69314718055994530941723212145818);  // index of first 'on' bit
        str = "p" + (string)(exponent + index - 26);  // reuse str
        mantissa = mantissa >> index;
        do str = llGetSubString( hexc, 15 & mantissa, 15 & mantissa ) + str;
        while ( mantissa = mantissa >> 4 );
        if ( input < 0 ) return "-0x" + str;
        return "0x" + str;
    }  // integers pack well so anything that qualifies as an integer we dump as such, supports negative zero
    return llDeleteSubString( (string)input, -7, -1 );  // trim off the float portion, return an integer
}

// Rounds the given float to the specified precision and returns it as string.
string shuiRoundFloat ( float val, integer prec )
{    
    float pow = llPow( 10, -prec ) * 0.5;
    if ( val  <  0 ) val -= pow; else val += pow;
    if ( prec <= 0 ) prec = -1;
    string strval = (string)val;
    return llGetSubString( strval, 0, llSubStringIndex( strval, "." ) + prec );
}

// Rounds the given vector to the specified precision and returns it as string.
string shuiRoundVec ( vector vec, integer prec )
{
    return "<" + shuiRoundFloat( vec.x, prec ) + ", " + shuiRoundFloat( vec.y, prec ) + ", " + shuiRoundFloat( vec.z, prec ) + ">";
}

// Returns whether the given string contains an integer.
integer shuiIsInteger ( string s )
{
    return (string)((integer)s) == s;
}

// Returns whether the given string contains a float.
integer shuiIsFloat ( string s )
{
    if ( llGetSubString( (s = llStringTrim( s, STRING_TRIM_HEAD )), 0, 0 ) == "0" ) return TRUE;  // only 0 handling
    return (string)((float)s) != (string)((float)("-" + s));  // doesn't distinguish +0 and -0
}

// Returns whether the given string is Base64-encoded.
integer shuiIsBase64 ( string s )
{
    // llXorBase64 doesn't exist in AVN, but llXorBase64StringsCorrect seems to work correctly like llXorBase64 there
    if ( llXorBase64StringsCorrect( s, "AAAA" ) != s ) return FALSE;  // by Strife Onizuka
    return (llStringToBase64( llBase64ToString( s ) ) == s);
}

// Returns whether the given string contains a vector.
// Uses the compiler to check it in two steps (to distinguish real ZERO_VECTOR from parsing error).
integer shuiIsVector ( string s )  // by Strife Onizuka, modified by Shuichi Shinji
{
    list split = llParseString2List( s, [], ["<", ">", ","] );
    if ( llGetListLength( split ) != 7 ) return FALSE;  // 3 elements, 2 commas, < and >
    //return !((string)((vector)s) == (string)((vector)((string)llListInsertList( split, ["-"], 5 ))));  // doesn't work in AVN
    if ( (vector)((string)llListReplaceList( split, [1], 5, 5 )) == ZERO_VECTOR ) return FALSE;  // parsing error in x or y
    return ((vector)((string)llListReplaceList( split, [1], 3, 3 )) != ZERO_VECTOR);             // parsing error in z
}

// Returns whether the given string contains a rotation.
// Uses the compiler to check it in two steps (to distinguish real ZERO_ROTATION from parsing error).
integer shuiIsRotation ( string s )  // by Strife Onizuka, modified by Shuichi Shinji
{
    list split = llParseString2List( s, [], ["<", ">", ","] );
    if ( llGetListLength( split ) != 9 ) return FALSE;  // 4 elements, 3 commas, < and >
    //return !((string)((vector)s) == (string)((vector)((string)llListInsertList( split, ["-"], 5 ))));  // doesn't work in AVN
    if ( (rotation)((string)llListReplaceList( split, [2], 7, 7 )) == ZERO_ROTATION ) return FALSE;   // parsing error in x, y or z
    return ((rotation)((string)llListReplaceList( split, [1], 5, 5 )) != ZERO_ROTATION);              // parsing error in s
}

// Normalize a rotation.
// Note: The only methods in LSL for obtaining a de-normalized rotations are llAxes2Rot (via inputs which are not
// mutually orthogonal, or via inputs of different magnitude), or direct manipulation of the rotation's elements.
// All other ll* functions return normalized rotations.
// This function may introduce small floating point errors into normalized rotations due to limited precision. 
rotation shuiNormRot ( rotation rot )  // from LSL Wiki
{
    float mag = llSqrt( rot.x * rot.x + rot.y * rot.y + rot.z * rot.z + rot.s * rot.s );
    return <rot.x / mag, rot.y / mag, rot.z / mag, rot.s / mag>;
}

// Scale a rotation.
rotation shuiScaleRot ( rotation rot, float ratio )  // from LSL Wiki
{
	return llAxisAngle2Rot( llRot2Axis( rot ), ratio * llRot2Angle( rot ) );
}

// Constrain a rotation to a given plane, defined by its normal, very useful for vehicles that remain horizontal in turns.
// Note that there is a flaw somewhere in this function, it gives incorrect results in some circumstances.
rotation shuiConstrainRotToPlane ( rotation rot, vector normal )  // by Jesrad Seraph
{
	return llAxisAngle2Rot( normal, <rot.x, rot.y, rot.z> * normal * llRot2Angle( rot ) );
}

// Written collectively, taken from http://forums-archive.secondlife.com/54/3b/50692/1.html
rotation shuiInterpolateRot ( rotation a, rotation b, float ratio )
{
	return llAxisAngle2Rot( llRot2Axis( b /= a ), ratio * llRot2Angle( b ) ) * a;
}

// Calculate a point at distance dist in the direction the avatar id is facing.
vector shuiGetPosInFrontOf ( key id, float dist )  // by Mephistopheles Thalheimer
{
    list pose = llGetObjectDetails( id, [ OBJECT_POS, OBJECT_ROT ] );
    return ( llList2Vector( pose, 0 ) + <dist, 0, 0> * llList2Rot( pose, 1 ) );
}

//-----------------------------------------------------------------------------
// Testframe, Part 01
//-----------------------------------------------------------------------------

integer Passed;
integer Failed;

checkResult ( string tc, string result, string expected )
{
    //if ( result == expected ) { llOwnerSay( tc + ": " + result + " -> PASSED" ); ++Passed; }
    if ( result == expected ) ++Passed;
    else { llOwnerSay( tc + ": " + result + " != " + expected + " -> FAILED" ); ++Failed; }
}

default
{
    touch_end ( integer num_detected )
    {
        key id = llDetectedKey( 0 );
        Passed = Failed = 0;
        llOwnerSay(  "-----------------------------------------------------------------------------" );
        checkResult( "[TC 1.1]  StrCompare(aa,aa)",  (string)shuiStrCompare( "aa", "aa"  ),  "0" );
        checkResult( "[TC 1.2]  StrCompare(aa,aaa)", (string)shuiStrCompare( "aa", "aaa" ), "-1" );
        checkResult( "[TC 1.3]  StrCompare(aa,ab)",  (string)shuiStrCompare( "aa", "ab"  ), "-1" );
        checkResult( "[TC 1.4]  StrCompare(ab,aa)",  (string)shuiStrCompare( "ab", "aa"  ),  "1" );
        checkResult( "[TC 1.5]  StrReplace(abbcccdddd,a,)",      shuiStrReplace ( "abbcccdddd", "a",  ""    ), "bbcccdddd"    );
        checkResult( "[TC 1.6]  StrReplace(abbcccdddd,b,)",      shuiStrReplace ( "abbcccdddd", "b",  ""    ), "acccdddd"     );
        checkResult( "[TC 1.7]  StrReplace(abbcccdddd,cc,)",     shuiStrReplace ( "abbcccdddd", "cc", ""    ), "abbcdddd"     );
        checkResult( "[TC 1.8]  StrReplace(abbcccdddd,dd,xyz)",  shuiStrReplace ( "abbcccdddd", "dd", "xyz" ), "abbcccxyzxyz" );
        checkResult( "[TC 1.9]  StrReplace2(abbcccdddd,a,)",     shuiStrReplace2( "abbcccdddd", "a",  ""    ), "bbcccdddd"    );
        checkResult( "[TC 1.10] StrReplace2(abbcccdddd,b,)",     shuiStrReplace2( "abbcccdddd", "b",  ""    ), "acccdddd"     );
        checkResult( "[TC 1.11] StrReplace2(abbcccdddd,cc,)",    shuiStrReplace2( "abbcccdddd", "cc", ""    ), "abbcdddd"     );
        checkResult( "[TC 1.12] StrReplace2(abbcccdddd,dd,xyz)", shuiStrReplace2( "abbcccdddd", "dd", "xyz" ), "abbcccxyzxyz" );
        checkResult( "[TC 1.13] FindMatch(abbcccdddd,bb,cd)",    shuiFindMatch  ( "abbcccdddd", "bb", "cd"  ), "cc"           );
        checkResult( "[TC 1.14] ParseString2List(a,bb,,c;dd;;e, FALSE)", llDumpList2String( shuiParseString2List( "a,bb,,c;dd;;e", [","], [";"], FALSE ), "-" ), "a-bb-c-;-dd-;-;-e" );
        checkResult( "[TC 1.15] ParseString2List(a,bb,,c;dd;;e, TRUE)",  llDumpList2String( shuiParseString2List( "a,bb,,c;dd;;e", [","], [";"], TRUE  ), "-" ), "a-bb--c-;-dd-;--;-e" );
        checkResult( "[TC 1.16] DecompressKey(CompressKey)", shuiDecompressKey( shuiCompressKey( id ) ), id );
        llOwnerSay(  "[TC 1.17] PrintString:" ); shuiPrintString( "aaa\nbbb\nccc\nddd\neee", 9 );
        llOwnerSay(  "[TC 1.18] PrintList:"   ); shuiPrintList  ( [ "aaa", "bbb", "ccc", "ddd", "eee" ], 9 );
        checkResult( "[TC 1.19] StringBytes(aou)", (string)shuiGetStringBytes( "aou" ), "3" );
        checkResult( "[TC 1.20] StringBytes(äöü)", (string)shuiGetStringBytes( "äöü" ), "6" );
        checkResult( "[TC 1.21] Ord7/8(A)", (string)shuiOrd7( "A" ) + "," + (string)shuiOrd8( "A" ), "65,65" );
        checkResult( "[TC 1.22] Ord7/8(Ä)", (string)shuiOrd7( "Ä" ) + "," + (string)shuiOrd8( "Ä" ), "-61,142" );
        checkResult( "[TC 1.23] Chr7/8(65)", shuiChr7( 65 ) + shuiChr8( 65 ), "AA" );
        checkResult( "[TC 1.24] Chr7/8(1)",  shuiChr7(  1 ) + shuiChr8(  1 ), "☺" );
        checkResult( "[TC 1.25] Integer2Hex(1234)",  shuiInteger2Hex(  1234 ), "0x4d2" );
        checkResult( "[TC 1.26] Integer2Hex(-1234)", shuiInteger2Hex( -1234 ), "0xfffffb2e" );
        checkResult( "[TC 1.27] Float2Hex(12.34)",   shuiFloat2Hex(  12.34 ), "0x315c29p-18" );
        checkResult( "[TC 1.28] Float2Hex(-12.34)",  shuiFloat2Hex( -12.34 ), "-0x315c29p-18" );
        checkResult( "[TC 2.1]  RoundFloat(0.0)",    shuiRoundFloat( 0.0, 1 ), "0.0" );
        checkResult( "[TC 2.2]  RoundFloat(0.1)",    shuiRoundFloat( 0.1, 1 ), "0.1" );
        checkResult( "[TC 2.3]  RoundFloat(0.499)",  shuiRoundFloat( 0.499, 0 ) + "," + shuiRoundFloat( 0.499, 1 ) + "," + shuiRoundFloat( 0.499, 2 ) + "," + shuiRoundFloat( 0.499, 3 ), "0,0.5,0.50,0.499" );
        checkResult( "[TC 2.4]  RoundFloat(0.5)",    shuiRoundFloat( 0.5, 1 ), "0.5" );
        checkResult( "[TC 2.5]  RoundFloat(0.949)",  shuiRoundFloat( 0.949, 0 ) + "," + shuiRoundFloat( 0.949, 1 ) + "," + shuiRoundFloat( 0.949, 2 ), "1,0.9,0.95" );
        checkResult( "[TC 2.6]  RoundFloat(0.95)",   shuiRoundFloat( 0.95,  0 ) + "," + shuiRoundFloat( 0.95,  1 ) + "," + shuiRoundFloat( 0.95,  2 ), "1,1.0,0.95" );
        checkResult( "[TC 2.7]  RoundFloat(1.001)",  shuiRoundFloat( 1.001, 1 ), "1.0" );
        checkResult( "[TC 2.8]  RoundFloat(-0.1)",   shuiRoundFloat( -0.1, 1 ), "-0.1" );
        checkResult( "[TC 2.9]  RoundFloat(-0.499)", shuiRoundFloat( -0.499, 0 ) + "," + shuiRoundFloat( -0.499, 1 ) + "," + shuiRoundFloat( -0.499, 2 ) + "," + shuiRoundFloat( -0.499, 3 ), "-0,-0.5,-0.50,-0.499" );
        checkResult( "[TC 2.10] RoundFloat(-0.5)",   shuiRoundFloat( -0.5, 1 ), "-0.5" );
        checkResult( "[TC 2.11] RoundFloat(-0.949)", shuiRoundFloat( -0.949, 0 ) + "," + shuiRoundFloat( -0.949, 1 ) + "," + shuiRoundFloat( -0.949, 2 ), "-1,-0.9,-0.95" );
        checkResult( "[TC 2.12] RoundFloat(-0.95)",  shuiRoundFloat( -0.95,  0 ) + "," + shuiRoundFloat( -0.95,  1 ) + "," + shuiRoundFloat( -0.95,  2 ), "-1,-1.0,-0.95" );
        checkResult( "[TC 2.13] RoundFloat(-1.001)", shuiRoundFloat( -1.001, 1 ), "-1.0" );
        checkResult( "[TC 2.14] RoundVec(<0.47,0.149,-1.001>,2)", shuiRoundVec( <0.47, 0.149, -1.001>, 2 ), "<0.47, 0.15, -1.00>" );
        checkResult( "[TC 3.1]  IsInteger(0)",                                (string)shuiIsInteger ( "0"     ),                             "1" );
        checkResult( "[TC 3.2]  IsInteger(47)",                               (string)shuiIsInteger ( "47"    ),                             "1" );
        checkResult( "[TC 3.3]  IsInteger(4T)",                               (string)shuiIsInteger ( "4T"    ),                             "0" );
        checkResult( "[TC 3.4]  IsInteger(47.3)",                             (string)shuiIsInteger ( "47.3"  ),                             "0" );
        checkResult( "[TC 3.5]  IsInteger(-47)",                              (string)shuiIsInteger ( "-47"   ),                             "1" );
        checkResult( "[TC 3.6]  IsInteger(A7)",                               (string)shuiIsInteger ( "A7"    ),                             "0" );
        checkResult( "[TC 3.7]  IsFloat(0)",                                  (string)shuiIsFloat   ( "0"     ),                             "1" );
        checkResult( "[TC 3.8]  IsFloat(0.0)",                                (string)shuiIsFloat   ( "0.0"   ),                             "1" );
        checkResult( "[TC 3.9]  IsFloat(47)",                                 (string)shuiIsFloat   ( "47"    ),                             "1" );
        checkResult( "[TC 3.10] IsFloat(4T)",                                 (string)shuiIsFloat   ( "4T"    ),                             "1" );
        checkResult( "[TC 3.11] IsFloat(47.3)",                               (string)shuiIsFloat   ( "47.3"  ),                             "1" );
        checkResult( "[TC 3.12] IsFloat(-47.3)",                              (string)shuiIsFloat   ( "-47.3" ),                             "1" );
        checkResult( "[TC 3.13] IsFloat(A7)",                                 (string)shuiIsFloat   ( "A7"    ),                             "0" );
        checkResult( "[TC 3.14] IsFloat(1E3)",                                (string)shuiIsFloat   ( "1E3"   ),                             "1" );
        checkResult( "[TC 3.15] IsFloat(1E-3)",                               (string)shuiIsFloat   ( "1E-3"  ),                             "1" );
        checkResult( "[TC 3.16] IsFloat(-1E3)",                               (string)shuiIsFloat   ( "-1E3"  ),                             "1" );
        checkResult( "[TC 3.17] IsFloat(-1E-3)",                              (string)shuiIsFloat   ( "-1E-3" ),                             "1" );
        checkResult( "[TC 3.18] IsBase64(QWJjZGU=)",                          (string)shuiIsBase64  ( "QWJjZGU="             ),              "1" );
        checkResult( "[TC 3.19] IsBase64(4pOQ4pOR4pOS4pOT4pOU)",              (string)shuiIsBase64  ( "4pOQ4pOR4pOS4pOT4pOU" ),              "1" );
        checkResult( "[TC 3.20] IsBase64(ABCD)",                              (string)shuiIsBase64  ( "ABCD"                 ),              "0" );
        checkResult( "[TC 3.21] IsBase64(ABC)",                               (string)shuiIsBase64  ( "ABC"                  ),              "0" );
        checkResult( "[TC 3.22] IsVector(<0.47,0.149, 1.001>)",               (string)shuiIsVector  ( "<0.47,0.149, 1.001>" ),               "1" );
        checkResult( "[TC 3.23] IsVector(<0.47,0.149, 1.001,3>)",             (string)shuiIsVector  ( "<0.47,0.149, 1.001,3>" ),             "0" );
        checkResult( "[TC 3.24] IsVector(<0.47,0.149,-1.001>)",               (string)shuiIsVector  ( "<0.47,0.149,-1.001>" ),               "1" );
        checkResult( "[TC 3.25] IsVector(<0.47,0.149,+1.001>)",               (string)shuiIsVector  ( "<0.47,0.149,+1.001>" ),               "1" );
        checkResult( "[TC 3.26] IsVector(<   0.47, 0.149,    -1.001   >)",    (string)shuiIsVector  ( "<   0.47, 0.149,    -1.001   >" ),    "1" );
        checkResult( "[TC 3.27] IsVector(  <   0.47, 0.149,    -1.001   > )", (string)shuiIsVector  ( "  <   0.47, 0.149,    -1.001   > " ), "0" );
        checkResult( "[TC 3.28] IsVector(<0.47,0.1A9,-1.001>)",               (string)shuiIsVector  ( "<0.47,0.1A9,-1.001>" ),               "0" );
        checkResult( "[TC 3.29] IsVector(<0.47,0.149,;-1.001>)",              (string)shuiIsVector  ( "<0.47,;0.149,-1.001>" ),              "0" );
        checkResult( "[TC 3.30] IsVector(<0.47,0.149,-1.001)",                (string)shuiIsVector  ( "<0.47,0.149,-1.001" ),                "0" );
        checkResult( "[TC 3.31] IsVector(<0,0.000,0>)",                       (string)shuiIsVector  ( "<0,0.000,0>" ),                       "1" );
        checkResult( "[TC 3.32] IsVector(<0,0.000,0,0>)",                     (string)shuiIsVector  ( "<0,0.000,0,0>" ),                     "0" );
        checkResult( "[TC 3.33] IsVector(<+0,-0.000,-0>)",                    (string)shuiIsVector  ( "<+0,-0.000,-0>" ),                    "1" );
        checkResult( "[TC 3.34] IsVector(<0x0.0,0x0p+1,-0x0p-1>)",            (string)shuiIsVector  ( "<0x0.0,0x0.p+1,-0x0.p-1>" ),          "1" );
        checkResult( "[TC 3.35] IsVector(<0.0e1,0.0e+1,-0.0e-1>)",            (string)shuiIsVector  ( "<0.0e1,0.0e+1,-0.0e-1>" ),            "1" );
        checkResult( "[TC 3.36] IsRotation(<0.47,0.149,-1.001>)",             (string)shuiIsRotation( "<0.47,0.149,-1.001>" ),               "0" );
        checkResult( "[TC 3.37] IsRotation(<0.47,0.149,-1.001,3>)",           (string)shuiIsRotation( "<0.47,0.149,-1.001,3>" ),             "1" );
        checkResult( "[TC 3.38] IsRotation(<0.47,0.149,+1.001,3>)",           (string)shuiIsRotation( "<0.47,0.149,+1.001,3>" ),             "1" );
        checkResult( "[TC 3.39] IsRotation(<  0.47, 0.149,   0.99,3  >)",     (string)shuiIsRotation( "<  0.47, 0.149,   0.99,3  >" ),       "1" );
        checkResult( "[TC 3.40] IsRotation(  <  0.47, 0.149,   0.99,3  > )",  (string)shuiIsRotation( "  <  0.47, 0.149,   0.99,3  > " ),    "0" );
        checkResult( "[TC 3.41] IsRotation(<0.47,0.1A9,-1.001,3>)",           (string)shuiIsRotation( "<0.47,0.1A9,-1.001,3>" ),             "0" );
        checkResult( "[TC 3.42] IsRotation(<0.47,0.149,-1.001,;3>)",          (string)shuiIsRotation( "<0.47,;0.149,-1.001,3>" ),            "0" );
        checkResult( "[TC 3.43] IsRotation(<0.47,0.149,-1.001,3)",            (string)shuiIsRotation( "<0.47,0.149,-1.001,3" ),              "0" );
        checkResult( "[TC 3.44] IsRotation(<0,0.000,0>)",                     (string)shuiIsRotation( "<0,0.000,0>" ),                       "0" );
        checkResult( "[TC 3.45] IsRotation(<0,0.000,0,0>)",                   (string)shuiIsRotation( "<0,0.000,0,0>" ),                     "1" );
        checkResult( "[TC 3.46] IsRotation(<+0,-0.000,-0,-0>)",               (string)shuiIsRotation( "<+0,-0.000,-0,-0>" ),                 "1" );
        llOwnerSay(  "[TC 4.1]  NormRot(<10,20,30,2>): "                  + (string)shuiNormRot( <10,20,30,2> ) );
        llOwnerSay(  "[TC 4.2]  ScaleRot(<10,20,30>,2): "                 + (string)(llRot2Euler( shuiScaleRot( llEuler2Rot( <10,20,30> * DEG_TO_RAD ), 2 ) ) * RAD_TO_DEG) );
        llOwnerSay(  "[TC 4.3]  ConstrainRotToPlane(<10,20,30>,XY): "     + (string)(llRot2Euler( shuiConstrainRotToPlane( llEuler2Rot( <10,20,30> * DEG_TO_RAD ), <0,0,1> ) ) * RAD_TO_DEG) );
        llOwnerSay(  "[TC 4.4]  InterpolateRot(<0,0,0>,<10,20,30>,0.5): " + (string)(llRot2Euler( shuiInterpolateRot( ZERO_ROTATION, llEuler2Rot( <10,20,30> * DEG_TO_RAD ), 0.5 ) ) * RAD_TO_DEG) );
        llOwnerSay(  "[TC 4.5]  GetPosInFrontOf(you,10): "                + (string)shuiGetPosInFrontOf( id, 10 ) );
        llOwnerSay(  "-----------------------------------------------------------------------------" );
        llOwnerSay(  "Test Result, Part 01: " + (string)Passed + " passed, " + (string)Failed + " failed" );
        llOwnerSay(  "-----------------------------------------------------------------------------" );
    }
}
