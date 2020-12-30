//=============================================================================
// Shui's Script Library v0.64, Part 02
// Copy the necessary functions to your scripts to use them.
//-----------------------------------------------------------------------------
// Copyright (c) 2012-2020, Shuichi Shinji
// Contains script examples from the LSL Wiki (c) the appropriate authors.
// See also http://wiki.secondlife.com/wiki/Combined_Library
// and http://wiki.secondlife.com/wiki/UTF-8.
// All rights reserved.
//-----------------------------------------------------------------------------
// Changelog: see Shui_Script_Library_01 script
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

// Returns whether we are running in Mono or not (LSO).
integer shuiIsMonoVM ()  // by Pedro Oval
{
    return !~-(integer)(""!="x");  // TRUE for Mono, FALSE for LSO, cast needed for AVN
}

// Returns a list of inventory items of the specified type(s).
list shuiGetInventoryList ( integer type )
{
    list    items;
    integer num = llGetInventoryNumber( type );
    while ( num ) items = [ llGetInventoryName( type, --num ) ] + items;
    return items;
}

// Returns prim number and face as "prim.face" from the specified prim name/number and face
// also as "prim.face" (case-insensitive). If not found, returns the specified default result
// and an error message is whispered on the specified channel or for the owner if -1.
// If no face specified, it is taken from the found prim's description.
string shuiGetPrimFace ( string prim_face, string result, integer chan )
{
    if ( prim_face )
    {
        string  prim  = prim_face;
        string  face  = ".-1";  // assume all faces
        integer cnt   = llGetNumberOfPrims();
        integer link  = !!(cnt - 1); cnt *= link;
        integer found = FALSE;  // prim not found yet
        integer pos   = llSubStringIndex( prim_face, "." );
        if ( ~pos )  // .face found
        {
            prim = llGetSubString( prim_face, 0, pos - 1 );
            face = llGetSubString( prim_face, pos, -1 );  // incl. dot
        }
        if ( (prim = llToLower( prim )) == "root" ) { result = (string)link; found = TRUE; }  // check for root prim
        for ( link = link; !found && link <= cnt; ++link )  // check every linked prim, 0 is only for unlinked
        {
            if ( prim == llToLower( llGetLinkName( link ) ) ) { result = (string)link; found = TRUE; }  // found, break
        }
        if ( !found && (string)((integer)prim) == prim ) { result = prim; found = TRUE; }  // check if number
        if ( found )  // add face
        {
            string desc = (string)llGetLinkPrimitiveParams( (integer)result, [PRIM_DESC] );
            if ( !~pos && (string)((integer)desc) == desc ) face = "." + desc;  // use desc if no face specified, only numbers
            result += face;  // incl. dot
        }
        else if ( ~chan ) llWhisper( chan, "Invalid prim/face: " + prim_face );  // error message
        else llOwnerSay( "Invalid prim/face: " + prim_face );
    }
    return result;
}

// Returns the number of prims in the object.
// Seated avatars are ignored.
integer shuiGetNumberOfPrims ()
{
    if ( llGetAttached() ) return llGetNumberOfPrims();
    return llGetObjectPrimCount( llGetKey() );
}

// Returns the number of seated avatars on the object.
integer shuiGetNumberOfAgents ()
{
    return llGetNumberOfPrims() - shuiGetNumberOfPrims();
}

// Returns a random channel for listeners.
// Ensures the channel isn't between 1 and 100 nor DEBUG_CHANNEL.
integer shuiGetRandomChannel ()
{
    integer chan = -1 - (integer)llFrand( -DEBUG_CHANNEL );
    if ( chan >= 0 && chan < 100 || chan == DEBUG_CHANNEL ) chan -= 200;
    return chan;
}

// Returns a channel for listeners, based on the given UUID.
// Ensures the channel isn't between 1 and 100 nor DEBUG_CHANNEL.
integer shuiGetChannelFor ( key id )
{
    integer chan = (integer)("0x" + llGetSubString( (string)id, -4, -1 ));
    if ( chan >= 0 && chan < 100 || chan == DEBUG_CHANNEL ) chan -= 200;
    return chan;
}

// Returns a channel for listeners, based on the given UUIDs and a custom offset.
// Ensures the channel isn't between 1 and 100 nor DEBUG_CHANNEL.
integer shuiGetChannelFor2 ( key id1, key id2, integer offset )
{
    integer chan = offset + (integer)("0x" + llGetSubString( (string)id1, -4, -1 ) + llGetSubString( (string)id2, -4, -1 ));
    if ( chan >= 0 && chan < 100 || chan == DEBUG_CHANNEL ) chan -= 200;
    return chan;
}

// Returns the legacy name of the agent with the given ID,
// but without " Resident".
string shuiGetLegacyName ( key id )
{
    string  legName = llKey2Name( id );
    integer pos     = llSubStringIndex( legName, " Resident" );
    if ( ~pos ) legName = llDeleteSubString( legName, pos, -1 );
    return legName;
}

// Returns the display name of the agent with the given ID.
// If only ??? can be read, it returns the legacy name instead.
string shuiGetDisplayName ( key id )
{
    string dispName = llGetDisplayName( id );
    if ( dispName == "???" ) dispName = shuiGetLegacyName( id );
    return dispName;
}

// Returns the first name of the agent with the given ID.
// If possible, the display name is used, otherwise the legacy name.
string shuiGetFirstName ( key id )
{
    string name = llGetDisplayName( id );
    if ( name == "???" ) name = llKey2Name( id );
    return llList2String( llParseString2List( name, [" "], [] ), 0 );
}

// Return combined display and legacy name of the agent with the given ID.
string shuiGetCombinedName ( key id )
{
    string legName  = shuiGetLegacyName( id );
    string dispName = shuiGetDisplayName( id );
    if ( dispName != legName ) dispName += " (" + legName + ")";
    return dispName;
}

// Return about name URL of the agent with the given ID.
// Suitable for display in the viewer (local chat).
string shuiGetAboutName ( key id )
{
    return "secondlife:///app/agent/" + (string)id + "/about";
}

// Return agent link URL of the agent with the given ID.
// Property can e.g. be "about", "inspect" and "im".
// Suitable for display in the viewer (local chat).
string shuiGetAgentLink ( key id, string prop )
{
    return "secondlife:///app/agent/" + (string)id + "/" + prop;
}

// Checks if agent is owner of the object. If object is group-owned,
// returns TRUE if agent belongs to the same group.
integer shuiIsOwner ( key id )
{
    key ownerID = llGetOwner();
    if ( id == ownerID ) return TRUE;
    if ( (string)llGetObjectDetails( llGetKey(), [OBJECT_GROUP] ) == ownerID ) return llSameGroup( id );
    return FALSE;
}

// Shows a dialog with buttons ordered correctly.
shuiShowDialog ( key id, string text, list buttons, integer chan )
{
    // sort the buttons so they appear in same order as in list
    buttons = llList2List( buttons, -3, -1 ) + llList2List( buttons, -6, -4 ) + llList2List( buttons, -9, -7 ) + llList2List( buttons, -12, -10 );
    llDialog( id, text, buttons, chan );
}

// Shows a menu dialog with buttons ordered correctly, a heading and timeout.
shuiShowMenu ( key id, string head, string text, list buttons, integer chan, integer timeout )
{
    string sep1 = "————————————————————————————\n  ";
    string sep2 = "\n" + sep1 + (string)llGetFreeMemory() + " bytes free. Timeout in " + (string)timeout + " seconds...";
    if ( text ) text = "\n\n" + text;  // add blank line
    // sort the buttons so they appear in same order as in list
    buttons = llList2List( buttons, -3, -1 ) + llList2List( buttons, -6, -4 ) + llList2List( buttons, -9, -7 ) + llList2List( buttons, -12, -10 );
    llDialog( id, sep1 + head + sep2 + text, buttons, chan );
    llSetTimerEvent( timeout );  // in seconds
}

// Returns time in milliseconds since the day began.
integer shuiGetTimeStamp ()
{
    string stamp = llGetTimestamp();  // "YYYY-MM-DDThh:mm:ss.ff..fZ"
    return (integer)llGetSubString( stamp, 11, 12 ) * 3600000 +  // hh
           (integer)llGetSubString( stamp, 14, 15 ) *   60000 +  // mm
           llRound( (float)llGetSubString( stamp, 17, -2 ) * 1000000.0 ) / 1000;  // ss.ff..f
}

// Returns whether the given year is a leap year.
integer shuiIsLeapYear ( integer y )
{
    return (!(y % 4) && (!!(y % 100) || (y <= 1582))) || !(y % 400);
}

// Returns the number of days in the given month for the specified year.
integer shuiGetDaysInMonth ( integer m, integer y )
{
    integer isLeapYear = (!(y % 4) && (!!(y % 100) || (y <= 1582))) || !(y % 400);
    return 30 + (((m > 7) + m) % 2) - ((2 - isLeapYear) * (m == 2));
}

// Returns the day of week for the given date, starting with 1 (Monday).
// Accurate from 1901 to 2099.
// Contains code by Void Singer, contributed freely to the Public Domain without limitation (CC0).
integer shuiGetDayOfWeek ( integer d, integer m, integer y )
{
    return (y + (y >> 2) - ((m < 3) & !(y & 3)) + d + (integer)llGetSubString( "_033614625035", m, m ) + 4) % 7 + 1;
}

// Returns the numeric day of year for the given date, starting with 1.
integer shuiGetDayOfYear ( integer d, integer m, integer y )
{
    integer isLeapYear = (!(y % 4) && (!!(y % 100) || (y <= 1582))) || !(y % 400);
    return d + (m - 1) * 30 + (((m > 8) + m) / 2) - ((2 - isLeapYear) * (m > 2));
}

// Returns the day of week (GMT/UTC or SLT/PST/PDT) for the given timestamp
// as returned by llGetUnixTime (GMT/UTC), starting with 1 (Monday).
// Contains code by Void Singer, contributed freely to the Public Domain without limitation (CC0).
integer shuiGetDayOfWeekTS ( integer timestamp, integer slt )
{
    // we take the unix time (GMT/UTC) and subtract the difference between both timezones and then calculate day of week from it
    if ( slt ) timestamp -= ((integer)llGetGMTclock() - (integer)llGetWallclock() + 86400) % 86400;  // timestamp is in GMT/UTC
    return (timestamp % 604800 / 86400 + (timestamp >> 31) + 3) % 7 + 1;  // 1-7 (Mon-Sun)
}

// Returns the day of month (GMT/UTC or SLT/PST/PDT) for the given timestamp
// as returned by llGetUnixTime (GMT/UTC), starting with 1.
// Time codes before 1902 or past the end of 2037 are capped to first second of 1902 and 2038, respectively.
// Contains code by Void Singer, contributed freely to the Public Domain without limitation (CC0).
integer shuiGetDayOfMonthTS ( integer timestamp, integer slt )
{
    // it would be easy to get the day of month in UTC, but there is no LSL function for SLT (PST/PDT)
    // so we take the unix time (GMT/UTC) and subtract the difference between both timezones and then calculate day of month from it
    if ( slt ) timestamp -= ((integer)llGetGMTclock() - (integer)llGetWallclock() + 86400) % 86400;  // timestamp is in GMT/UTC
    if ( timestamp / 2145916800 ) timestamp = 2145916800 * (1 | timestamp >> 31);
    timestamp %= 126230400; timestamp -= 126230400 * (timestamp >> 31);
    integer mday = timestamp / 86400;
    if ( 789 == mday ) return 29;
    integer tmp;
    mday -= (mday > 789); mday %= 365; mday += timestamp = 1;
    while ( mday > (tmp = (30 | (timestamp & 1) ^ (timestamp > 7)) - ((timestamp == 2) << 1)) ) { ++timestamp; mday -= tmp; }
    return mday;
}

// Converts a color and alpha value into an ARGB integer.
integer shuiColorAlpha2ARGB ( vector color, float alpha )
{
    return (((integer)(alpha   * 255.0) & 0xff) << 24) |
           (((integer)(color.x * 255.0) & 0xff) << 16) |
           (((integer)(color.y * 255.0) & 0xff) <<  8) |
            ((integer)(color.z * 255.0) & 0xff);
}

// Gets color from ARGB integer.
vector shuiARGB2Color ( integer argb )
{
    return <((argb >> 16) & 0xff) / 255.0, ((argb >> 8) & 0xff) / 255.0, (argb & 0xff) / 255.0>;
}
 
// Gets alpha from ARGB integer.
float shuiARGB2Alpha ( integer argb )
{
    return ((argb >> 24) & 0xff) / 255.0;
}

//-----------------------------------------------------------------------------
// Testframe, Part 02
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
        key id    = llDetectedKey( 0 );
        key owner = llGetOwner();
        llSleep( 5 );
        Passed = Failed = 0;
        llOwnerSay(  "-----------------------------------------------------------------------------" );
        llOwnerSay(  "[TC 5.1]  IsMonoVM: " + (string)shuiIsMonoVM() );
        llOwnerSay(  "[TC 5.2]  Inventory: " + llList2CSV( shuiGetInventoryList( INVENTORY_ALL ) ) );
        llOwnerSay(  "[TC 5.3]  GetPrimFace(0): "  + shuiGetPrimFace( "Prim", "-1", 0 ) );
        llOwnerSay(  "[TC 5.4]  GetPrimFace(-1): " + shuiGetPrimFace( "1.4", "",   -1 ) );
        llOwnerSay(  "[TC 5.5]  NumberOfPrims: "   + (string)shuiGetNumberOfPrims()  + " - sit and repeat test" );
        llOwnerSay(  "[TC 5.6]  NumberOfAgents: "  + (string)shuiGetNumberOfAgents() + " - sit and repeat test" );
        llOwnerSay(  "[TC 6.1]  RandomChannel: "   + (string)shuiGetRandomChannel() + ", " + (string)shuiGetRandomChannel() );
        llOwnerSay(  "[TC 6.2]  ChannelFor(you): " + (string)shuiGetChannelFor(id) + ", " + (string)shuiGetChannelFor(id) );
        llOwnerSay(  "[TC 6.3]  ChannelFor(obj): " + (string)shuiGetChannelFor( llGetKey() ) + ", " + (string)shuiGetChannelFor( llGetKey() ) );
        llOwnerSay(  "[TC 6.4]  ChannelFor2(owner,creator,1): " + (string)shuiGetChannelFor2( owner, llGetCreator(), 1 ) + ", " + (string)shuiGetChannelFor2( owner, llGetCreator(), 1 ) );
        llOwnerSay(  "[TC 7.1]  LegacyName: "   + shuiGetLegacyName  ( id ) );
        llOwnerSay(  "[TC 7.2]  DisplayName: "  + shuiGetDisplayName ( id ) );
        llOwnerSay(  "[TC 7.3]  FirstName: "    + shuiGetFirstName   ( id ) );
        llOwnerSay(  "[TC 7.4]  CombinedName: " + shuiGetCombinedName( id ) );
        llOwnerSay(  "[TC 7.5]  AboutName: "    + shuiGetAboutName   ( id ) );
        llOwnerSay(  "[TC 7.6]  AgentLink(about): "   + shuiGetAgentLink( id, "about"   ) );
        llOwnerSay(  "[TC 7.7]  AgentLink(inspect): " + shuiGetAgentLink( id, "inspect" ) );
        llOwnerSay(  "[TC 7.8]  AgentLink(im): "      + shuiGetAgentLink( id, "im"      ) );
        checkResult( "[TC 7.9]  IsOwner(owner)",   (string)shuiIsOwner( owner ), "1" );
        checkResult( "[TC 7.10] IsOwner(toucher)", (string)shuiIsOwner( id    ), "1" );
        llOwnerSay(  "[TC 8.1]  GetTimeStamp(): " + (string)shuiGetTimeStamp() );
        llOwnerSay(  "[TC 8.2]  GetTimeStamp(): " + (string)shuiGetTimeStamp() );
        checkResult( "[TC 8.3]  IsLeapYear(1500)", (string)shuiIsLeapYear( 1500 ), "1" );
        checkResult( "[TC 8.4]  IsLeapYear(1580)", (string)shuiIsLeapYear( 1580 ), "1" );
        checkResult( "[TC 8.5]  IsLeapYear(1582)", (string)shuiIsLeapYear( 1582 ), "0" );
        checkResult( "[TC 8.6]  IsLeapYear(1600)", (string)shuiIsLeapYear( 1600 ), "1" );
        checkResult( "[TC 8.7]  IsLeapYear(1700)", (string)shuiIsLeapYear( 1700 ), "0" );
        checkResult( "[TC 8.8]  IsLeapYear(2000)", (string)shuiIsLeapYear( 2000 ), "1" );
        checkResult( "[TC 8.9]  IsLeapYear(2012)", (string)shuiIsLeapYear( 2012 ), "1" );
        checkResult( "[TC 8.10] IsLeapYear(2014)", (string)shuiIsLeapYear( 2014 ), "0" );
        checkResult( "[TC 8.11] IsLeapYear(2100)", (string)shuiIsLeapYear( 2100 ), "0" );
        checkResult( "[TC 8.12] DaysInMonth(1-12,1500)",
            (string)shuiGetDaysInMonth( 1,1500) + "," + (string)shuiGetDaysInMonth( 2,1500) + "," + (string)shuiGetDaysInMonth( 3,1500) + "," +
            (string)shuiGetDaysInMonth( 4,1500) + "," + (string)shuiGetDaysInMonth( 5,1500) + "," + (string)shuiGetDaysInMonth( 6,1500) + "," +
            (string)shuiGetDaysInMonth( 7,1500) + "," + (string)shuiGetDaysInMonth( 8,1500) + "," + (string)shuiGetDaysInMonth( 9,1500) + "," +
            (string)shuiGetDaysInMonth(10,1500) + "," + (string)shuiGetDaysInMonth(11,1500) + "," + (string)shuiGetDaysInMonth(12,1500), "31,29,31,30,31,30,31,31,30,31,30,31" );
        checkResult( "[TC 8.13] DaysInMonth(1-12,1580)",
            (string)shuiGetDaysInMonth( 1,1580) + "," + (string)shuiGetDaysInMonth( 2,1580) + "," + (string)shuiGetDaysInMonth( 3,1580) + "," +
            (string)shuiGetDaysInMonth( 4,1580) + "," + (string)shuiGetDaysInMonth( 5,1580) + "," + (string)shuiGetDaysInMonth( 6,1580) + "," +
            (string)shuiGetDaysInMonth( 7,1580) + "," + (string)shuiGetDaysInMonth( 8,1580) + "," + (string)shuiGetDaysInMonth( 9,1580) + "," +
            (string)shuiGetDaysInMonth(10,1580) + "," + (string)shuiGetDaysInMonth(11,1580) + "," + (string)shuiGetDaysInMonth(12,1580), "31,29,31,30,31,30,31,31,30,31,30,31" );
        checkResult( "[TC 8.14] DaysInMonth(1-12,1900)",
            (string)shuiGetDaysInMonth( 1,1900) + "," + (string)shuiGetDaysInMonth( 2,1900) + "," + (string)shuiGetDaysInMonth( 3,1900) + "," +
            (string)shuiGetDaysInMonth( 4,1900) + "," + (string)shuiGetDaysInMonth( 5,1900) + "," + (string)shuiGetDaysInMonth( 6,1900) + "," +
            (string)shuiGetDaysInMonth( 7,1900) + "," + (string)shuiGetDaysInMonth( 8,1900) + "," + (string)shuiGetDaysInMonth( 9,1900) + "," +
            (string)shuiGetDaysInMonth(10,1900) + "," + (string)shuiGetDaysInMonth(11,1900) + "," + (string)shuiGetDaysInMonth(12,1900), "31,28,31,30,31,30,31,31,30,31,30,31" );
        checkResult( "[TC 8.15] DaysInMonth(1-12,2000)",
            (string)shuiGetDaysInMonth( 1,2000) + "," + (string)shuiGetDaysInMonth( 2,2000) + "," + (string)shuiGetDaysInMonth( 3,2000) + "," +
            (string)shuiGetDaysInMonth( 4,2000) + "," + (string)shuiGetDaysInMonth( 5,2000) + "," + (string)shuiGetDaysInMonth( 6,2000) + "," +
            (string)shuiGetDaysInMonth( 7,2000) + "," + (string)shuiGetDaysInMonth( 8,2000) + "," + (string)shuiGetDaysInMonth( 9,2000) + "," +
            (string)shuiGetDaysInMonth(10,2000) + "," + (string)shuiGetDaysInMonth(11,2000) + "," + (string)shuiGetDaysInMonth(12,2000), "31,29,31,30,31,30,31,31,30,31,30,31" );
        checkResult( "[TC 8.16] DaysInMonth(1-12,2012)",
            (string)shuiGetDaysInMonth( 1,2012) + "," + (string)shuiGetDaysInMonth( 2,2012) + "," + (string)shuiGetDaysInMonth( 3,2012) + "," +
            (string)shuiGetDaysInMonth( 4,2012) + "," + (string)shuiGetDaysInMonth( 5,2012) + "," + (string)shuiGetDaysInMonth( 6,2012) + "," +
            (string)shuiGetDaysInMonth( 7,2012) + "," + (string)shuiGetDaysInMonth( 8,2012) + "," + (string)shuiGetDaysInMonth( 9,2012) + "," +
            (string)shuiGetDaysInMonth(10,2012) + "," + (string)shuiGetDaysInMonth(11,2012) + "," + (string)shuiGetDaysInMonth(12,2012), "31,29,31,30,31,30,31,31,30,31,30,31" );
        checkResult( "[TC 8.17] DayOfWeek(1.1.+28.2.+29.2.+1.3.+30.4.+1.5.+31.7.+1.8.+1.9.+31.12.1901)",
            (string)shuiGetDayOfWeek(1,1,1901)  + "," + (string)shuiGetDayOfWeek(28,2,1901) + "," + (string)shuiGetDayOfWeek(29,2,1901) + "," +
            (string)shuiGetDayOfWeek(1,3,1901)  + "," + (string)shuiGetDayOfWeek(30,4,1901) + "," + (string)shuiGetDayOfWeek(1,5,1901)  + "," +
            (string)shuiGetDayOfWeek(31,7,1901) + "," + (string)shuiGetDayOfWeek(1,8,1901)  + "," + (string)shuiGetDayOfWeek(1,9,1901)  + "," +
            (string)shuiGetDayOfWeek(31,12,1901), "2,4,5,5,2,3,3,4,7,2" );
        checkResult( "[TC 8.18] DayOfWeek(1.1.+28.2.+29.2.+1.3.+30.4.+1.5.+31.7.+1.8.+1.9.+31.12.2000)",
            (string)shuiGetDayOfWeek(1,1,2000)  + "," + (string)shuiGetDayOfWeek(28,2,2000) + "," + (string)shuiGetDayOfWeek(29,2,2000) + "," +
            (string)shuiGetDayOfWeek(1,3,2000)  + "," + (string)shuiGetDayOfWeek(30,4,2000) + "," + (string)shuiGetDayOfWeek(1,5,2000)  + "," +
            (string)shuiGetDayOfWeek(31,7,2000) + "," + (string)shuiGetDayOfWeek(1,8,2000)  + "," + (string)shuiGetDayOfWeek(1,9,2000)  + "," +
            (string)shuiGetDayOfWeek(31,12,2000), "6,1,2,3,7,1,1,2,5,7" );
        checkResult( "[TC 8.19] DayOfYear(1.1.+28.2.+29.2.+1.3.+30.4.+1.5.+31.7.+1.8.+1.9.+31.12.1900)",
            (string)shuiGetDayOfYear(1,1,1900)  + "," + (string)shuiGetDayOfYear(28,2,1900) + "," + (string)shuiGetDayOfYear(29,2,1900) + "," +
            (string)shuiGetDayOfYear(1,3,1900)  + "," + (string)shuiGetDayOfYear(30,4,1900) + "," + (string)shuiGetDayOfYear(1,5,1900)  + "," +
            (string)shuiGetDayOfYear(31,7,1900) + "," + (string)shuiGetDayOfYear(1,8,1900)  + "," + (string)shuiGetDayOfYear(1,9,1900)  + "," +
            (string)shuiGetDayOfYear(31,12,1900), "1,59,60,60,120,121,212,213,244,365" );
        checkResult( "[TC 8.20] DayOfYear(1.1.+28.2.+29.2.+1.3.+30.4.+1.5.+31.7.+1.8.+1.9.+31.12.2000)",
            (string)shuiGetDayOfYear(1,1,2000)  + "," + (string)shuiGetDayOfYear(28,2,2000) + "," + (string)shuiGetDayOfYear(29,2,2000) + "," +
            (string)shuiGetDayOfYear(1,3,2000)  + "," + (string)shuiGetDayOfYear(30,4,2000) + "," + (string)shuiGetDayOfYear(1,5,2000)  + "," +
            (string)shuiGetDayOfYear(31,7,2000) + "," + (string)shuiGetDayOfYear(1,8,2000)  + "," + (string)shuiGetDayOfYear(1,9,2000)  + "," +
            (string)shuiGetDayOfYear(31,12,2000), "1,59,60,61,121,122,213,214,245,366" );
        integer ts = llGetUnixTime();
        llOwnerSay(  "[TC 8.21] DayOfWeekTS(UTC+0/12/24h): "  + (string)shuiGetDayOfWeekTS ( ts, FALSE ) + "," + (string)shuiGetDayOfWeekTS ( ts + 43200, FALSE ) + "," + (string)shuiGetDayOfWeekTS ( ts + 86400, FALSE ) );
        llOwnerSay(  "[TC 8.22] DayOfWeekTS(SLT+0/12/24h): "  + (string)shuiGetDayOfWeekTS ( ts, TRUE  ) + "," + (string)shuiGetDayOfWeekTS ( ts + 43200, TRUE  ) + "," + (string)shuiGetDayOfWeekTS ( ts + 86400, TRUE  ) );
        llOwnerSay(  "[TC 8.23] DayOfMonthTS(UTC+0/12/24h): " + (string)shuiGetDayOfMonthTS( ts, FALSE ) + "," + (string)shuiGetDayOfMonthTS( ts + 43200, FALSE ) + "," + (string)shuiGetDayOfMonthTS( ts + 86400, FALSE ) );
        llOwnerSay(  "[TC 8.24] DayOfMonthTS(SLT+0/12/24h): " + (string)shuiGetDayOfMonthTS( ts, TRUE  ) + "," + (string)shuiGetDayOfMonthTS( ts + 43200, TRUE  ) + "," + (string)shuiGetDayOfMonthTS( ts + 86400, TRUE  ) );
        checkResult( "[TC 9.1]  ColorAlpha2ARGB(<1.0,0.6,0.4>, 0.2)", (string)shuiColorAlpha2ARGB( <1.0,0.6,0.4>, 0.2 ), "872388966" );
        checkResult( "[TC 9.2]  ARGB2Color(0x33ff9966)", (string)shuiARGB2Color( 0x33ff9966 ), "<1.00000, 0.60000, 0.40000>" );
        checkResult( "[TC 9.3]  ARGB2Alpha(0x33ff9966)", (string)shuiARGB2Alpha( 0x33ff9966 ), "0.200000" );
        shuiShowMenu( id, "TEST MENU", "[TC 10.1] Verify order of buttons:",
            [ "Button 1", "Button 2", "Button 3", "Button 4", "Button 5", "Button 6",
              "Button 7", "Button 8", "Button 9", "Button 10", "Button 11", "Button 12" ], 0, 30 );
        llOwnerSay(  "-----------------------------------------------------------------------------" );
        llOwnerSay(  "Test Result, Part 02: " + (string)Passed + " passed, " + (string)Failed + " failed" );
        llOwnerSay(  "-----------------------------------------------------------------------------" );
    }
    
    timer ()  // after menu timeout
    {
        shuiShowDialog( llGetOwner(), "[TC 10.2] Verify order of buttons:",
            [ "Button 1", "Button 2", "Button 3", "Button 4", "Button 5", "Button 6",
              "Button 7", "Button 8", "Button 9", "Button 10", "Button 11", "Button 12" ], 0 );
    }
}
