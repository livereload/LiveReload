<?php
/**
 * To validate an email address according to RFCs 5321, 5322 and others
 *
 * Copyright © 2008-2011, Dominic Sayers                    <br>
 * Test schema documentation Copyright © 2011, Daniel Marschall            <br>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *     - Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     - Redistributions in binary form must reproduce the above copyright notice,
 *       this list of conditions and the following disclaimer in the documentation
 *       and/or other materials provided with the distribution.
 *     - Neither the name of Dominic Sayers nor the names of its contributors may be
 *       used to endorse or promote products derived from this software without
 *       specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @package    is_email
 * @author    Dominic Sayers <dominic@sayers.cc>
 * @copyright    2008-2011 Dominic Sayers
 * @license    http://www.opensource.org/licenses/bsd-license.php BSD License
 * @link    http://www.dominicsayers.com/isemail
 * @version    3.01.1 - Fixed examples and readme.txt
 */

// The quality of this code has been improved greatly by using PHPLint
// Copyright (c) 2010 Umberto Salsi
// This is free software; see the license for copying conditions.
// More info: http://www.icosaedro.it/phplint/
/*.
    require_module 'standard';
    require_module 'pcre';
.*/

if (!defined('ISEMAIL_VALID')) {
/*:diagnostic constants start:*/
// This part of the code is generated using data from test/meta.xml. Beware of making manual alterations
    // Categories
    define('ISEMAIL_VALID_CATEGORY', 1);
    define('ISEMAIL_DNSWARN', 7);
    define('ISEMAIL_RFC5321', 15);
    define('ISEMAIL_CFWS', 31);
    define('ISEMAIL_DEPREC', 63);
    define('ISEMAIL_RFC5322', 127);
    define('ISEMAIL_ERR', 255);

    // Diagnoses
    // Address is valid
    define('ISEMAIL_VALID', 0);
    // Address is valid but a DNS check was not successful
    define('ISEMAIL_DNSWARN_NO_MX_RECORD', 5);
    define('ISEMAIL_DNSWARN_NO_RECORD', 6);
    // Address is valid for SMTP but has unusual elements
    define('ISEMAIL_RFC5321_TLD', 9);
    define('ISEMAIL_RFC5321_TLDNUMERIC', 10);
    define('ISEMAIL_RFC5321_QUOTEDSTRING', 11);
    define('ISEMAIL_RFC5321_ADDRESSLITERAL', 12);
    define('ISEMAIL_RFC5321_IPV6DEPRECATED', 13);
    // Address is valid within the message but cannot be used unmodified for the envelope
    define('ISEMAIL_CFWS_COMMENT', 17);
    define('ISEMAIL_CFWS_FWS', 18);
    // Address contains deprecated elements but may still be valid in restricted contexts
    define('ISEMAIL_DEPREC_LOCALPART', 33);
    define('ISEMAIL_DEPREC_FWS', 34);
    define('ISEMAIL_DEPREC_QTEXT', 35);
    define('ISEMAIL_DEPREC_QP', 36);
    define('ISEMAIL_DEPREC_COMMENT', 37);
    define('ISEMAIL_DEPREC_CTEXT', 38);
    define('ISEMAIL_DEPREC_CFWS_NEAR_AT', 49);
    // The address is only valid according to the broad definition of RFC 5322. It is otherwise invalid.
    define('ISEMAIL_RFC5322_DOMAIN', 65);
    define('ISEMAIL_RFC5322_TOOLONG', 66);
    define('ISEMAIL_RFC5322_LOCAL_TOOLONG', 67);
    define('ISEMAIL_RFC5322_DOMAIN_TOOLONG', 68);
    define('ISEMAIL_RFC5322_LABEL_TOOLONG', 69);
    define('ISEMAIL_RFC5322_DOMAINLITERAL', 70);
    define('ISEMAIL_RFC5322_DOMLIT_OBSDTEXT', 71);
    define('ISEMAIL_RFC5322_IPV6_GRPCOUNT', 72);
    define('ISEMAIL_RFC5322_IPV6_2X2XCOLON', 73);
    define('ISEMAIL_RFC5322_IPV6_BADCHAR', 74);
    define('ISEMAIL_RFC5322_IPV6_MAXGRPS', 75);
    define('ISEMAIL_RFC5322_IPV6_COLONSTRT', 76);
    define('ISEMAIL_RFC5322_IPV6_COLONEND', 77);
    // Address is invalid for any purpose
    define('ISEMAIL_ERR_EXPECTING_DTEXT', 129);
    define('ISEMAIL_ERR_NOLOCALPART', 130);
    define('ISEMAIL_ERR_NODOMAIN', 131);
    define('ISEMAIL_ERR_CONSECUTIVEDOTS', 132);
    define('ISEMAIL_ERR_ATEXT_AFTER_CFWS', 133);
    define('ISEMAIL_ERR_ATEXT_AFTER_QS', 134);
    define('ISEMAIL_ERR_ATEXT_AFTER_DOMLIT', 135);
    define('ISEMAIL_ERR_EXPECTING_QPAIR', 136);
    define('ISEMAIL_ERR_EXPECTING_ATEXT', 137);
    define('ISEMAIL_ERR_EXPECTING_QTEXT', 138);
    define('ISEMAIL_ERR_EXPECTING_CTEXT', 139);
    define('ISEMAIL_ERR_BACKSLASHEND', 140);
    define('ISEMAIL_ERR_DOT_START', 141);
    define('ISEMAIL_ERR_DOT_END', 142);
    define('ISEMAIL_ERR_DOMAINHYPHENSTART', 143);
    define('ISEMAIL_ERR_DOMAINHYPHENEND', 144);
    define('ISEMAIL_ERR_UNCLOSEDQUOTEDSTR', 145);
    define('ISEMAIL_ERR_UNCLOSEDCOMMENT', 146);
    define('ISEMAIL_ERR_UNCLOSEDDOMLIT', 147);
    define('ISEMAIL_ERR_FWS_CRLF_X2', 148);
    define('ISEMAIL_ERR_FWS_CRLF_END', 149);
    define('ISEMAIL_ERR_CR_NO_LF', 150);
// End of generated code
/*:diagnostic constants end:*/

    // function control
    define('ISEMAIL_THRESHOLD'        , 16);

    // Email parts
    define('ISEMAIL_COMPONENT_LOCALPART'    , 0);
    define('ISEMAIL_COMPONENT_DOMAIN'    , 1);
    define('ISEMAIL_COMPONENT_LITERAL'    , 2);
    define('ISEMAIL_CONTEXT_COMMENT'    , 3);
    define('ISEMAIL_CONTEXT_FWS'        , 4);
    define('ISEMAIL_CONTEXT_QUOTEDSTRING'    , 5);
    define('ISEMAIL_CONTEXT_QUOTEDPAIR'    , 6);

    // Miscellaneous string constants
    define('ISEMAIL_STRING_AT'        , '@');
    define('ISEMAIL_STRING_BACKSLASH'    , '\\');
    define('ISEMAIL_STRING_DOT'        , '.');
    define('ISEMAIL_STRING_DQUOTE'        , '"');
    define('ISEMAIL_STRING_OPENPARENTHESIS'    , '(');
    define('ISEMAIL_STRING_CLOSEPARENTHESIS', ')');
    define('ISEMAIL_STRING_OPENSQBRACKET'    , '[');
    define('ISEMAIL_STRING_CLOSESQBRACKET'    , ']');
    define('ISEMAIL_STRING_HYPHEN'        , '-');
    define('ISEMAIL_STRING_COLON'        , ':');
    define('ISEMAIL_STRING_DOUBLECOLON'    , '::');
    define('ISEMAIL_STRING_SP'        , ' ');
    define('ISEMAIL_STRING_HTAB'        , "\t");
    define('ISEMAIL_STRING_CR'        , "\r");
    define('ISEMAIL_STRING_LF'        , "\n");
    define('ISEMAIL_STRING_IPV6TAG'        , 'IPv6:');
    // US-ASCII visible characters not valid for atext (http://tools.ietf.org/html/rfc5322#section-3.2.3)
    define('ISEMAIL_STRING_SPECIALS'    , '()<>[]:;@\\,."');
}

/**
 * Check that an email address conforms to RFCs 5321, 5322 and others
 *
 * As of Version 3.0, we are now distinguishing clearly between a Mailbox
 * as defined by RFC 5321 and an addr-spec as defined by RFC 5322. Depending
 * on the context, either can be regarded as a valid email address. The
 * RFC 5321 Mailbox specification is more restrictive (comments, white space
 * and obsolete forms are not allowed)
 *
 * @param string    $email        The email address to check
 * @param boolean    $checkDNS    If true then a DNS check for MX records will be made
 * @param mixed        $errorlevel    Determines the boundary between valid and invalid addresses.
 *                     Status codes above this number will be returned as-is,
 *                     status codes below will be returned as ISEMAIL_VALID. Thus the
 *                     calling program can simply look for ISEMAIL_VALID if it is
 *                     only interested in whether an address is valid or not. The
 *                     errorlevel will determine how "picky" is_email() is about
 *                     the address.
 *
 *                     If omitted or passed as false then is_email() will return
 *                     true or false rather than an integer error or warning.
 *
 *                     NB Note the difference between $errorlevel = false and
 *                     $errorlevel = 0
 * @param array        $parsedata    If passed, returns the parsed address components
 */
/*.mixed.*/ function is_email($email, $checkDNS = false, $errorlevel = false, &$parsedata = array()) {
    // Check that $email is a valid address. Read the following RFCs to understand the constraints:
    //     (http://tools.ietf.org/html/rfc5321)
    //     (http://tools.ietf.org/html/rfc5322)
    //     (http://tools.ietf.org/html/rfc4291#section-2.2)
    //     (http://tools.ietf.org/html/rfc1123#section-2.1)
    //     (http://tools.ietf.org/html/rfc3696) (guidance only)
// version 2.0: Enhance $diagnose parameter to $errorlevel
// version 3.0: Introduced status categories
// revision 3.1: BUG: $parsedata was passed by value instead of by reference

    if (is_bool($errorlevel)) {
        $threshold    = ISEMAIL_VALID;
        $diagnose    = (bool) $errorlevel;
    } else {
        $diagnose    = true;

        switch ((int) $errorlevel) {
        case E_WARNING:    $threshold    = ISEMAIL_THRESHOLD;    break;    // For backward compatibility
        case E_ERROR:    $threshold    = ISEMAIL_VALID;    break;    // For backward compatibility
        default:    $threshold    = (int) $errorlevel;
        }
    }

    $return_status = array(ISEMAIL_VALID);

    // Parse the address into components, character by character
    $raw_length    = strlen($email);
    $context    = ISEMAIL_COMPONENT_LOCALPART;    // Where we are
    $context_stack    = array($context);        // Where we have been
    $context_prior    = ISEMAIL_COMPONENT_LOCALPART;    // Where we just came from
    $token        = '';                // The current character
    $token_prior    = '';                // The previous character
    $parsedata    = array(
                ISEMAIL_COMPONENT_LOCALPART    => '',
                ISEMAIL_COMPONENT_DOMAIN    => ''
                   );            // For the components of the address

    $atomlist    = array(
                ISEMAIL_COMPONENT_LOCALPART    => array(''),
                ISEMAIL_COMPONENT_DOMAIN    => array('')
                   );            // For the dot-atom elements of the address
    $element_count    = 0;
    $element_len    = 0;
    $hyphen_flag    = false;            // Hyphen cannot occur at the end of a subdomain
    $end_or_die    = false;            // CFWS can only appear at the end of the element

//-echo "<table style=\"clear:left;\">"; // debug
    for ($i = 0; $i < $raw_length; $i++) {
        $token = $email[$i];
//-echo "<tr><td><strong>$context|",(($end_or_die) ? 'true' : 'false'),"|$token|" . max($return_status) . "</strong></td>"; // debug

        switch ($context) {
        //-------------------------------------------------------------
        // local-part
        //-------------------------------------------------------------
        case ISEMAIL_COMPONENT_LOCALPART:
            // http://tools.ietf.org/html/rfc5322#section-3.4.1
            //   local-part      =   dot-atom / quoted-string / obs-local-part
            //
            //   dot-atom        =   [CFWS] dot-atom-text [CFWS]
            //
            //   dot-atom-text   =   1*atext *("." 1*atext)
            //
            //   quoted-string   =   [CFWS]
            //                       DQUOTE *([FWS] qcontent) [FWS] DQUOTE
            //                       [CFWS]
            //
            //   obs-local-part  =   word *("." word)
            //
            //   word            =   atom / quoted-string
            //
            //   atom            =   [CFWS] 1*atext [CFWS]
            switch ($token) {
            // Comment
            case ISEMAIL_STRING_OPENPARENTHESIS:
                if ($element_len === 0)
                    // Comments are OK at the beginning of an element
                    $return_status[]    = ($element_count === 0) ? ISEMAIL_CFWS_COMMENT : ISEMAIL_DEPREC_COMMENT;
                else {
                    $return_status[]    = ISEMAIL_CFWS_COMMENT;
                    $end_or_die        = true;    // We can't start a comment in the middle of an element, so this better be the end
                }

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_COMMENT;
                break;
            // Next dot-atom element
            case ISEMAIL_STRING_DOT:
                if ($element_len === 0)
                    // Another dot, already?
                    $return_status[] = ($element_count === 0) ? ISEMAIL_ERR_DOT_START : ISEMAIL_ERR_CONSECUTIVEDOTS;    // Fatal error
                else
                    // The entire local-part can be a quoted string for RFC 5321
                    // If it's just one atom that is quoted then it's an RFC 5322 obsolete form
                    if ($end_or_die) $return_status[] = ISEMAIL_DEPREC_LOCALPART;

                    $end_or_die    = false;    // CFWS & quoted strings are OK again now we're at the beginning of an element (although they are obsolete forms)
                    $element_len    = 0;
                    $element_count++;
                    $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                    $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    = '';

                break;
            // Quoted string
            case ISEMAIL_STRING_DQUOTE:
                if ($element_len === 0) {
                    // The entire local-part can be a quoted string for RFC 5321
                    // If it's just one atom that is quoted then it's an RFC 5322 obsolete form
                    $return_status[]    = ($element_count === 0) ? ISEMAIL_RFC5321_QUOTEDSTRING : ISEMAIL_DEPREC_LOCALPART;

                    $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                    $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= $token;
                    $element_len++;
                    $end_or_die        = true;    // Quoted string must be the entire element
                    $context_stack[]    = $context;
                    $context        = ISEMAIL_CONTEXT_QUOTEDSTRING;
                } else {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_ATEXT;    // Fatal error
                }

                break;
            // Folding White Space
            case ISEMAIL_STRING_CR:
            case ISEMAIL_STRING_SP:
            case ISEMAIL_STRING_HTAB:
                if (($token === ISEMAIL_STRING_CR) && ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))) {$return_status[] = ISEMAIL_ERR_CR_NO_LF;    break;}    // Fatal error

                if ($element_len === 0)
                    $return_status[] = ($element_count === 0) ? ISEMAIL_CFWS_FWS : ISEMAIL_DEPREC_FWS;
                else
                    $end_or_die = true;    // We can't start FWS in the middle of an element, so this better be the end

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_FWS;
                $token_prior        = $token;

                break;
            // @
            case ISEMAIL_STRING_AT:
                // At this point we should have a valid local-part
                if (count($context_stack) !== 1) die('Unexpected item on context stack');

                if    ($parsedata[ISEMAIL_COMPONENT_LOCALPART] === '')
                                $return_status[]    = ISEMAIL_ERR_NOLOCALPART;    // Fatal error
                elseif    ($element_len === 0)    $return_status[]    = ISEMAIL_ERR_DOT_END;    // Fatal error
                // http://tools.ietf.org/html/rfc5321#section-4.5.3.1.1
                //   The maximum total length of a user name or other local-part is 64
                //   octets.
                elseif    (strlen($parsedata[ISEMAIL_COMPONENT_LOCALPART]) > 64)
                                $return_status[]    = ISEMAIL_RFC5322_LOCAL_TOOLONG;
                // http://tools.ietf.org/html/rfc5322#section-3.4.1
                //   Comments and folding white space
                //   SHOULD NOT be used around the "@" in the addr-spec.
                //
                // http://tools.ietf.org/html/rfc2119
                // 4. SHOULD NOT   This phrase, or the phrase "NOT RECOMMENDED" mean that
                //    there may exist valid reasons in particular circumstances when the
                //    particular behavior is acceptable or even useful, but the full
                //    implications should be understood and the case carefully weighed
                //    before implementing any behavior described with this label.
                elseif    (($context_prior === ISEMAIL_CONTEXT_COMMENT) || ($context_prior === ISEMAIL_CONTEXT_FWS))
                                $return_status[]    = ISEMAIL_DEPREC_CFWS_NEAR_AT;

                // Clear everything down for the domain parsing
                $context    = ISEMAIL_COMPONENT_DOMAIN;    // Where we are
                $context_stack    = array($context);        // Where we have been
                $element_count    = 0;
                $element_len    = 0;
                $end_or_die    = false;            // CFWS can only appear at the end of the element

                break;
            // atext
            default:
                // http://tools.ietf.org/html/rfc5322#section-3.2.3
                //    atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
                //                        "!" / "#" /        ;  characters not including
                //                        "$" / "%" /        ;  specials.  Used for atoms.
                //                        "&" / "'" /
                //                        "*" / "+" /
                //                        "-" / "/" /
                //                        "=" / "?" /
                //                        "^" / "_" /
                //                        "`" / "{" /
                //                        "|" / "}" /
                //                        "~"
                if ($end_or_die) {
                    // We have encountered atext where it is no longer valid
                    switch ($context_prior) {
                    case ISEMAIL_CONTEXT_COMMENT:
                    case ISEMAIL_CONTEXT_FWS:
                        $return_status[]    = ISEMAIL_ERR_ATEXT_AFTER_CFWS;
                        break;
                    case ISEMAIL_CONTEXT_QUOTEDSTRING:
                        $return_status[]    = ISEMAIL_ERR_ATEXT_AFTER_QS;
                        break;
                    default:
                        die ("More atext found where none is allowed, but unrecognised prior context: $context_prior");
                    }
                } else {
                    $context_prior    = $context;
                    $ord        = ord($token);

                    if (($ord < 33) || ($ord > 126) || ($ord === 10) || (!is_bool(strpos(ISEMAIL_STRING_SPECIALS, $token))))
                        $return_status[]    = ISEMAIL_ERR_EXPECTING_ATEXT;    // Fatal error

                    $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                    $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= $token;
                    $element_len++;
                }
            }

            break;
        //-------------------------------------------------------------
        // Domain
        //-------------------------------------------------------------
        case ISEMAIL_COMPONENT_DOMAIN:
            // http://tools.ietf.org/html/rfc5322#section-3.4.1
            //   domain          =   dot-atom / domain-literal / obs-domain
            //
            //   dot-atom        =   [CFWS] dot-atom-text [CFWS]
            //
            //   dot-atom-text   =   1*atext *("." 1*atext)
            //
            //   domain-literal  =   [CFWS] "[" *([FWS] dtext) [FWS] "]" [CFWS]
            //
            //   dtext           =   %d33-90 /          ; Printable US-ASCII
            //                       %d94-126 /         ;  characters not including
            //                       obs-dtext          ;  "[", "]", or "\"
            //
            //   obs-domain      =   atom *("." atom)
            //
            //   atom            =   [CFWS] 1*atext [CFWS]


            // http://tools.ietf.org/html/rfc5321#section-4.1.2
            //   Mailbox        = Local-part "@" ( Domain / address-literal )
            //
            //   Domain         = sub-domain *("." sub-domain)
            //
            //   address-literal  = "[" ( IPv4-address-literal /
            //                    IPv6-address-literal /
            //                    General-address-literal ) "]"
            //                    ; See Section 4.1.3

            // http://tools.ietf.org/html/rfc5322#section-3.4.1
            //      Note: A liberal syntax for the domain portion of addr-spec is
            //      given here.  However, the domain portion contains addressing
            //      information specified by and used in other protocols (e.g.,
            //      [RFC1034], [RFC1035], [RFC1123], [RFC5321]).  It is therefore
            //      incumbent upon implementations to conform to the syntax of
            //      addresses for the context in which they are used.
            // is_email() author's note: it's not clear how to interpret this in
            // the context of a general email address validator. The conclusion I
            // have reached is this: "addressing information" must comply with
            // RFC 5321 (and in turn RFC 1035), anything that is "semantically
            // invisible" must comply only with RFC 5322.
            switch ($token) {
            // Comment
            case ISEMAIL_STRING_OPENPARENTHESIS:
                if ($element_len === 0)
                    // Comments at the start of the domain are deprecated in the text
                    // Comments at the start of a subdomain are obs-domain
                    // (http://tools.ietf.org/html/rfc5322#section-3.4.1)
                    $return_status[]    = ($element_count === 0) ? ISEMAIL_DEPREC_CFWS_NEAR_AT : ISEMAIL_DEPREC_COMMENT;
                else {
                    $return_status[]    = ISEMAIL_CFWS_COMMENT;
                    $end_or_die        = true;    // We can't start a comment in the middle of an element, so this better be the end
                }

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_COMMENT;
                break;
            // Next dot-atom element
            case ISEMAIL_STRING_DOT:
                if ($element_len === 0)
                    // Another dot, already?
                    $return_status[]    = ($element_count === 0) ? ISEMAIL_ERR_DOT_START : ISEMAIL_ERR_CONSECUTIVEDOTS;    // Fatal error
                elseif ($hyphen_flag)
                    // Previous subdomain ended in a hyphen
                    $return_status[]    = ISEMAIL_ERR_DOMAINHYPHENEND;    // Fatal error
                else
                    // Nowhere in RFC 5321 does it say explicitly that the
                    // domain part of a Mailbox must be a valid domain according
                    // to the DNS standards set out in RFC 1035, but this *is*
                    // implied in several places. For instance, wherever the idea
                    // of host routing is discussed the RFC says that the domain
                    // must be looked up in the DNS. This would be nonsense unless
                    // the domain was designed to be a valid DNS domain. Hence we
                    // must conclude that the RFC 1035 restriction on label length
                    // also applies to RFC 5321 domains.
                    //
                    // http://tools.ietf.org/html/rfc1035#section-2.3.4
                    // labels          63 octets or less
                    if ($element_len > 63) $return_status[]    = ISEMAIL_RFC5322_LABEL_TOOLONG;

                    $end_or_die        = false;    // CFWS is OK again now we're at the beginning of an element (although it may be obsolete CFWS)
                    $element_len        = 0;
                    $element_count++;
                    $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    = '';
                    $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;

                break;
            // Domain literal
            case ISEMAIL_STRING_OPENSQBRACKET:
                if ($parsedata[ISEMAIL_COMPONENT_DOMAIN] === '') {
                    $end_or_die        = true;    // Domain literal must be the only component
                    $element_len++;
                    $context_stack[]    = $context;
                    $context        = ISEMAIL_COMPONENT_LITERAL;
                    $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;
                    $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    .= $token;
                    $parsedata[ISEMAIL_COMPONENT_LITERAL]            = '';
                } else {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_ATEXT;    // Fatal error
                }

                break;
            // Folding White Space
            case ISEMAIL_STRING_CR:
            case ISEMAIL_STRING_SP:
            case ISEMAIL_STRING_HTAB:
                if (($token === ISEMAIL_STRING_CR) && ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))) {$return_status[] = ISEMAIL_ERR_CR_NO_LF;    break;}    // Fatal error

                if ($element_len === 0)
                    $return_status[]    = ($element_count === 0) ? ISEMAIL_DEPREC_CFWS_NEAR_AT : ISEMAIL_DEPREC_FWS;
                else {
                    $return_status[]    = ISEMAIL_CFWS_FWS;
                    $end_or_die    = true;    // We can't start FWS in the middle of an element, so this better be the end
                }

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_FWS;
                $token_prior        = $token;
                break;
            // atext
            default:
                // RFC 5322 allows any atext...
                // http://tools.ietf.org/html/rfc5322#section-3.2.3
                //    atext           =   ALPHA / DIGIT /    ; Printable US-ASCII
                //                        "!" / "#" /        ;  characters not including
                //                        "$" / "%" /        ;  specials.  Used for atoms.
                //                        "&" / "'" /
                //                        "*" / "+" /
                //                        "-" / "/" /
                //                        "=" / "?" /
                //                        "^" / "_" /
                //                        "`" / "{" /
                //                        "|" / "}" /
                //                        "~"

                // But RFC 5321 only allows letter-digit-hyphen to comply with DNS rules (RFCs 1034 & 1123)
                // http://tools.ietf.org/html/rfc5321#section-4.1.2
                //   sub-domain     = Let-dig [Ldh-str]
                //
                //   Let-dig        = ALPHA / DIGIT
                //
                //   Ldh-str        = *( ALPHA / DIGIT / "-" ) Let-dig
                //
                if ($end_or_die) {
                    // We have encountered atext where it is no longer valid
                    switch ($context_prior) {
                    case ISEMAIL_CONTEXT_COMMENT:
                    case ISEMAIL_CONTEXT_FWS:
                        $return_status[]    = ISEMAIL_ERR_ATEXT_AFTER_CFWS;
                        break;
                    case ISEMAIL_COMPONENT_LITERAL:
                        $return_status[]    = ISEMAIL_ERR_ATEXT_AFTER_DOMLIT;
                        break;
                    default:
                        die ("More atext found where none is allowed, but unrecognised prior context: $context_prior");
                    }
                }

                $ord        = ord($token);
                $hyphen_flag    = false;    // Assume this token isn't a hyphen unless we discover it is

                if (($ord < 33) || ($ord > 126) || (!is_bool(strpos(ISEMAIL_STRING_SPECIALS, $token)))) {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_ATEXT;    // Fatal error
                } elseif ($token === ISEMAIL_STRING_HYPHEN) {
                    if ($element_len === 0) {
                        // Hyphens can't be at the beginning of a subdomain
                        $return_status[]    = ISEMAIL_ERR_DOMAINHYPHENSTART;    // Fatal error
                    }

                    $hyphen_flag = true;
                } elseif (!(($ord > 47 && $ord < 58) || ($ord > 64 && $ord < 91) || ($ord > 96 && $ord < 123))) {
                    // Not an RFC 5321 subdomain, but still OK by RFC 5322
                    $return_status[]    = ISEMAIL_RFC5322_DOMAIN;
                }

                $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    .= $token;
                $element_len++;
            }

            break;
        //-------------------------------------------------------------
        // Domain literal
        //-------------------------------------------------------------
        case ISEMAIL_COMPONENT_LITERAL:
            // http://tools.ietf.org/html/rfc5322#section-3.4.1
            //   domain-literal  =   [CFWS] "[" *([FWS] dtext) [FWS] "]" [CFWS]
            //
            //   dtext           =   %d33-90 /          ; Printable US-ASCII
            //                       %d94-126 /         ;  characters not including
            //                       obs-dtext          ;  "[", "]", or "\"
            //
            //   obs-dtext       =   obs-NO-WS-CTL / quoted-pair
            switch ($token) {
            // End of domain literal
            case ISEMAIL_STRING_CLOSESQBRACKET:
                if ((int) max($return_status) < ISEMAIL_DEPREC) {
                    // Could be a valid RFC 5321 address literal, so let's check

                    // http://tools.ietf.org/html/rfc5321#section-4.1.2
                    //   address-literal  = "[" ( IPv4-address-literal /
                    //                    IPv6-address-literal /
                    //                    General-address-literal ) "]"
                    //                    ; See Section 4.1.3
                    //
                    // http://tools.ietf.org/html/rfc5321#section-4.1.3
                    //   IPv4-address-literal  = Snum 3("."  Snum)
                    //
                    //   IPv6-address-literal  = "IPv6:" IPv6-addr
                    //
                    //   General-address-literal  = Standardized-tag ":" 1*dcontent
                    //
                    //   Standardized-tag  = Ldh-str
                    //                     ; Standardized-tag MUST be specified in a
                    //                     ; Standards-Track RFC and registered with IANA
                    //
                    //   dcontent       = %d33-90 / ; Printable US-ASCII
                    //                  %d94-126 ; excl. "[", "\", "]"
                    //
                    //   Snum           = 1*3DIGIT
                    //                  ; representing a decimal integer
                    //                  ; value in the range 0 through 255
                    //
                    //   IPv6-addr      = IPv6-full / IPv6-comp / IPv6v4-full / IPv6v4-comp
                    //
                    //   IPv6-hex       = 1*4HEXDIG
                    //
                    //   IPv6-full      = IPv6-hex 7(":" IPv6-hex)
                    //
                    //   IPv6-comp      = [IPv6-hex *5(":" IPv6-hex)] "::"
                    //                  [IPv6-hex *5(":" IPv6-hex)]
                    //                  ; The "::" represents at least 2 16-bit groups of
                    //                  ; zeros.  No more than 6 groups in addition to the
                    //                  ; "::" may be present.
                    //
                    //   IPv6v4-full    = IPv6-hex 5(":" IPv6-hex) ":" IPv4-address-literal
                    //
                    //   IPv6v4-comp    = [IPv6-hex *3(":" IPv6-hex)] "::"
                    //                  [IPv6-hex *3(":" IPv6-hex) ":"]
                    //                  IPv4-address-literal
                    //                  ; The "::" represents at least 2 16-bit groups of
                    //                  ; zeros.  No more than 4 groups in addition to the
                    //                  ; "::" and IPv4-address-literal may be present.
                    //
                    // is_email() author's note: We can't use ip2long() to validate
                    // IPv4 addresses because it accepts abbreviated addresses
                    // (xxx.xxx.xxx), expanding the last group to complete the address.
                    // filter_var() validates IPv6 address inconsistently (up to PHP 5.3.3
                    // at least) -- see http://bugs.php.net/bug.php?id=53236 for example
                    $max_groups    = 8;
                    $matchesIP    = array();
            /*.mixed.*/    $index        = false;
                    $addressliteral    = $parsedata[ISEMAIL_COMPONENT_LITERAL];

                    // Extract IPv4 part from the end of the address-literal (if there is one)
                    if (preg_match('/\\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/', $addressliteral, $matchesIP) > 0) {
                        $index = strrpos($addressliteral, $matchesIP[0]);
                        if ($index !== 0) $addressliteral = substr($addressliteral, 0, $index) . '0:0'; // Convert IPv4 part to IPv6 format for further testing
                    }

                    if ($index === 0) {
                        // Nothing there except a valid IPv4 address, so...
                        $return_status[]    = ISEMAIL_RFC5321_ADDRESSLITERAL;
                    } elseif (strncasecmp($addressliteral, ISEMAIL_STRING_IPV6TAG, 5) !== 0) {
                        $return_status[]    = ISEMAIL_RFC5322_DOMAINLITERAL;
                    } else {
                        $IPv6        = substr($addressliteral, 5);
                        $matchesIP    = explode(ISEMAIL_STRING_COLON, $IPv6);    // Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                        $groupCount    = count($matchesIP);
                        $index        = strpos($IPv6,ISEMAIL_STRING_DOUBLECOLON);

                        if ($index === false) {
                            // We need exactly the right number of groups
                            if ($groupCount !== $max_groups)
                                $return_status[]    = ISEMAIL_RFC5322_IPV6_GRPCOUNT;
                        } else {
                            if ($index !== strrpos($IPv6,ISEMAIL_STRING_DOUBLECOLON))
                                $return_status[]    = ISEMAIL_RFC5322_IPV6_2X2XCOLON;
                            else {
                                if ($index === 0 || $index === (strlen($IPv6) - 2)) $max_groups++;    // RFC 4291 allows :: at the start or end of an address with 7 other groups in addition

                                if ($groupCount > $max_groups)
                                    $return_status[]    = ISEMAIL_RFC5322_IPV6_MAXGRPS;
                                elseif ($groupCount === $max_groups)
                                    $return_status[]    = ISEMAIL_RFC5321_IPV6DEPRECATED;    // Eliding a single "::"
                            }
                        }

                        // Revision 2.7: Daniel Marschall's new IPv6 testing strategy
                        if ((substr($IPv6, 0,  1) === ISEMAIL_STRING_COLON) && (substr($IPv6, 1,  1) !== ISEMAIL_STRING_COLON))
                            $return_status[]    = ISEMAIL_RFC5322_IPV6_COLONSTRT;    // Address starts with a single colon
                        elseif ((substr($IPv6, -1) === ISEMAIL_STRING_COLON) && (substr($IPv6, -2, 1) !== ISEMAIL_STRING_COLON))
                            $return_status[]    = ISEMAIL_RFC5322_IPV6_COLONEND;    // Address ends with a single colon
                        elseif (count(preg_grep('/^[0-9A-Fa-f]{0,4}$/', $matchesIP, PREG_GREP_INVERT)) !== 0)
                            $return_status[]    = ISEMAIL_RFC5322_IPV6_BADCHAR;    // Check for unmatched characters
                        else
                            $return_status[]    = ISEMAIL_RFC5321_ADDRESSLITERAL;
                    }
                } else
                    $return_status[]    = ISEMAIL_RFC5322_DOMAINLITERAL;


                $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    .= $token;
                $element_len++;
                $context_prior        = $context;
                $context        = (int) array_pop($context_stack);
                break;
            case ISEMAIL_STRING_BACKSLASH:
                $return_status[]    = ISEMAIL_RFC5322_DOMLIT_OBSDTEXT;
                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_QUOTEDPAIR;
                break;
            // Folding White Space
            case ISEMAIL_STRING_CR:
            case ISEMAIL_STRING_SP:
            case ISEMAIL_STRING_HTAB:
                if (($token === ISEMAIL_STRING_CR) && ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))) {$return_status[] = ISEMAIL_ERR_CR_NO_LF;    break;}    // Fatal error

                $return_status[]    = ISEMAIL_CFWS_FWS;

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_FWS;
                $token_prior        = $token;
                break;
            // dtext
            default:
                // http://tools.ietf.org/html/rfc5322#section-3.4.1
                //   dtext           =   %d33-90 /          ; Printable US-ASCII
                //                       %d94-126 /         ;  characters not including
                //                       obs-dtext          ;  "[", "]", or "\"
                //
                //   obs-dtext       =   obs-NO-WS-CTL / quoted-pair
                //
                //   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                //                       %d11 /             ;  characters that do not
                //                       %d12 /             ;  include the carriage
                //                       %d14-31 /          ;  return, line feed, and
                //                       %d127              ;  white space characters
                $ord = ord($token);

                // CR, LF, SP & HTAB have already been parsed above
                if (($ord > 127) || ($ord === 0) || ($token === ISEMAIL_STRING_OPENSQBRACKET)) {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_DTEXT;    // Fatal error
                    break;
                } elseif (($ord < 33) || ($ord === 127)) {
                    $return_status[]    = ISEMAIL_RFC5322_DOMLIT_OBSDTEXT;
                }

                $parsedata[ISEMAIL_COMPONENT_LITERAL]            .= $token;
                $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    .= $token;
                $element_len++;
            }

            break;
        //-------------------------------------------------------------
        // Quoted string
        //-------------------------------------------------------------
        case ISEMAIL_CONTEXT_QUOTEDSTRING:
            // http://tools.ietf.org/html/rfc5322#section-3.2.4
            //   quoted-string   =   [CFWS]
            //                       DQUOTE *([FWS] qcontent) [FWS] DQUOTE
            //                       [CFWS]
            //
            //   qcontent        =   qtext / quoted-pair
            switch ($token) {
            // Quoted pair
            case ISEMAIL_STRING_BACKSLASH:
                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_QUOTEDPAIR;
                break;
            // Folding White Space
            // Inside a quoted string, spaces are allowed as regular characters.
            // It's only FWS if we include HTAB or CRLF
            case ISEMAIL_STRING_CR:
            case ISEMAIL_STRING_HTAB:
                if (($token === ISEMAIL_STRING_CR) && ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))) {$return_status[] = ISEMAIL_ERR_CR_NO_LF;    break;}    // Fatal error

                // http://tools.ietf.org/html/rfc5322#section-3.2.2
                //   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                //   structured header field are semantically interpreted as a single
                //   space character.

                // http://tools.ietf.org/html/rfc5322#section-3.2.4
                //   the CRLF in any FWS/CFWS that appears within the quoted-string [is]
                //   semantically "invisible" and therefore not part of the quoted-string
                $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= ISEMAIL_STRING_SP;
                $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= ISEMAIL_STRING_SP;
                $element_len++;

                $return_status[]        = ISEMAIL_CFWS_FWS;
                $context_stack[]        = $context;
                $context            = ISEMAIL_CONTEXT_FWS;
                $token_prior            = $token;
                break;
            // End of quoted string
            case ISEMAIL_STRING_DQUOTE:
                $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= $token;
                $element_len++;
                $context_prior            = $context;
                $context            = (int) array_pop($context_stack);
                break;
            // qtext
            default:
                // http://tools.ietf.org/html/rfc5322#section-3.2.4
                //   qtext           =   %d33 /             ; Printable US-ASCII
                //                       %d35-91 /          ;  characters not including
                //                       %d93-126 /         ;  "\" or the quote character
                //                       obs-qtext
                //
                //   obs-qtext       =   obs-NO-WS-CTL
                //
                //   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                //                       %d11 /             ;  characters that do not
                //                       %d12 /             ;  include the carriage
                //                       %d14-31 /          ;  return, line feed, and
                //                       %d127              ;  white space characters
                $ord = ord($token);

                if (($ord > 127) || ($ord === 0) || ($ord === 10)) {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_QTEXT;    // Fatal error
                } elseif (($ord < 32) || ($ord === 127))
                    $return_status[]    = ISEMAIL_DEPREC_QTEXT;

                $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= $token;
                $element_len++;
            }

            // http://tools.ietf.org/html/rfc5322#section-3.4.1
            //   If the
            //   string can be represented as a dot-atom (that is, it contains no
            //   characters other than atext characters or "." surrounded by atext
            //   characters), then the dot-atom form SHOULD be used and the quoted-
            //   string form SHOULD NOT be used.
// To do
            break;
        //-------------------------------------------------------------
        // Quoted pair
        //-------------------------------------------------------------
        case ISEMAIL_CONTEXT_QUOTEDPAIR:
            // http://tools.ietf.org/html/rfc5322#section-3.2.1
            //   quoted-pair     =   ("\" (VCHAR / WSP)) / obs-qp
            //
            //   VCHAR           =  %d33-126            ; visible (printing) characters
            //   WSP             =  SP / HTAB           ; white space
            //
            //   obs-qp          =   "\" (%d0 / obs-NO-WS-CTL / LF / CR)
            //
            //   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
            //                       %d11 /             ;  characters that do not
            //                       %d12 /             ;  include the carriage
            //                       %d14-31 /          ;  return, line feed, and
            //                       %d127              ;  white space characters
            //
            // i.e. obs-qp       =  "\" (%d0-8, %d10-31 / %d127)
            $ord = ord($token);

            if    ($ord > 127)
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_QPAIR;    // Fatal error
            elseif    ((($ord < 31) && ($ord !== 9)) || ($ord === 127))    // SP & HTAB are allowed
                    $return_status[]    = ISEMAIL_DEPREC_QP;

            // At this point we know where this qpair occurred so
            // we could check to see if the character actually
            // needed to be quoted at all.
            // http://tools.ietf.org/html/rfc5321#section-4.1.2
            //   the sending system SHOULD transmit the
            //   form that uses the minimum quoting possible.
// To do: check whether the character needs to be quoted (escaped) in this context
            $context_prior    = $context;
            $context    = (int) array_pop($context_stack);    // End of qpair
            $token        = ISEMAIL_STRING_BACKSLASH . $token;

            switch ($context) {
            case ISEMAIL_CONTEXT_COMMENT:
                break;
            case ISEMAIL_CONTEXT_QUOTEDSTRING:
                $parsedata[ISEMAIL_COMPONENT_LOCALPART]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_LOCALPART][$element_count]    .= $token;
                $element_len    += 2;    // The maximum sizes specified by RFC 5321 are octet counts, so we must include the backslash
                break;
            case ISEMAIL_COMPONENT_LITERAL:
                $parsedata[ISEMAIL_COMPONENT_DOMAIN]            .= $token;
                $atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count]    .= $token;
                $element_len    += 2;    // The maximum sizes specified by RFC 5321 are octet counts, so we must include the backslash
                break;
            default:
                die("Quoted pair logic invoked in an invalid context: $context");
            }

            break;
        //-------------------------------------------------------------
        // Comment
        //-------------------------------------------------------------
        case ISEMAIL_CONTEXT_COMMENT:
            // http://tools.ietf.org/html/rfc5322#section-3.2.2
            //   comment         =   "(" *([FWS] ccontent) [FWS] ")"
            //
            //   ccontent        =   ctext / quoted-pair / comment
            switch ($token) {
            // Nested comment
            case ISEMAIL_STRING_OPENPARENTHESIS:
                // Nested comments are OK
                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_COMMENT;
                break;
            // End of comment
            case ISEMAIL_STRING_CLOSEPARENTHESIS:
                $context_prior        = $context;
                $context        = (int) array_pop($context_stack);

                // http://tools.ietf.org/html/rfc5322#section-3.2.2
                //   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                //   structured header field are semantically interpreted as a single
                //   space character.
                //
                // is_email() author's note: This *cannot* mean that we must add a
                // space to the address wherever CFWS appears. This would result in
                // any addr-spec that had CFWS outside a quoted string being invalid
                // for RFC 5321.
//                if (($context === ISEMAIL_COMPONENT_LOCALPART) || ($context === ISEMAIL_COMPONENT_DOMAIN)) {
//                    $parsedata[$context]            .= ISEMAIL_STRING_SP;
//                    $atomlist[$context][$element_count]    .= ISEMAIL_STRING_SP;
//                    $element_len++;
//                }

                break;
            // Quoted pair
            case ISEMAIL_STRING_BACKSLASH:
                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_QUOTEDPAIR;
                break;
            // Folding White Space
            case ISEMAIL_STRING_CR:
            case ISEMAIL_STRING_SP:
            case ISEMAIL_STRING_HTAB:
                if (($token === ISEMAIL_STRING_CR) && ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))) {$return_status[] = ISEMAIL_ERR_CR_NO_LF;    break;}    // Fatal error

                $return_status[]    = ISEMAIL_CFWS_FWS;

                $context_stack[]    = $context;
                $context        = ISEMAIL_CONTEXT_FWS;
                $token_prior        = $token;
                break;
            // ctext
            default:
                // http://tools.ietf.org/html/rfc5322#section-3.2.3
                //   ctext           =   %d33-39 /          ; Printable US-ASCII
                //                       %d42-91 /          ;  characters not including
                //                       %d93-126 /         ;  "(", ")", or "\"
                //                       obs-ctext
                //
                //   obs-ctext       =   obs-NO-WS-CTL
                //
                //   obs-NO-WS-CTL   =   %d1-8 /            ; US-ASCII control
                //                       %d11 /             ;  characters that do not
                //                       %d12 /             ;  include the carriage
                //                       %d14-31 /          ;  return, line feed, and
                //                       %d127              ;  white space characters
                $ord = ord($token);

                if (($ord > 127) || ($ord === 0) || ($ord === 10)) {
                    $return_status[]    = ISEMAIL_ERR_EXPECTING_CTEXT;    // Fatal error
                    break;
                } elseif (($ord < 32) || ($ord === 127)) {
                    $return_status[]    = ISEMAIL_DEPREC_CTEXT;
                }
            }

            break;
        //-------------------------------------------------------------
        // Folding White Space
        //-------------------------------------------------------------
        case ISEMAIL_CONTEXT_FWS:
            // http://tools.ietf.org/html/rfc5322#section-3.2.2
            //   FWS             =   ([*WSP CRLF] 1*WSP) /  obs-FWS
            //                                          ; Folding white space

            // But note the erratum:
            // http://www.rfc-editor.org/errata_search.php?rfc=5322&eid=1908:
            //   In the obsolete syntax, any amount of folding white space MAY be
            //   inserted where the obs-FWS rule is allowed.  This creates the
            //   possibility of having two consecutive "folds" in a line, and
            //   therefore the possibility that a line which makes up a folded header
            //   field could be composed entirely of white space.
            //
            //   obs-FWS         =   1*([CRLF] WSP)
            if ($token_prior === ISEMAIL_STRING_CR) {
                if ($token === ISEMAIL_STRING_CR) {
                    $return_status[]    = ISEMAIL_ERR_FWS_CRLF_X2;    // Fatal error
                    break;
                }

                if (isset($crlf_count)) {
                    if (++$crlf_count > 1)
                        $return_status[]    = ISEMAIL_DEPREC_FWS;    // Multiple folds = obsolete FWS
                } else $crlf_count = 1;
            }

            switch ($token) {
            case ISEMAIL_STRING_CR:
                if ((++$i === $raw_length) || ($email[$i] !== ISEMAIL_STRING_LF))
                    $return_status[]    = ISEMAIL_ERR_CR_NO_LF;    // Fatal error

                break;
            case ISEMAIL_STRING_SP:
            case ISEMAIL_STRING_HTAB:
                break;
            default:
                if ($token_prior === ISEMAIL_STRING_CR) {
                    $return_status[]    = ISEMAIL_ERR_FWS_CRLF_END;    // Fatal error
                    break;
                }

                if (isset($crlf_count)) unset($crlf_count);

                $context_prior                    = $context;
                $context                    = (int) array_pop($context_stack);    // End of FWS

                // http://tools.ietf.org/html/rfc5322#section-3.2.2
                //   Runs of FWS, comment, or CFWS that occur between lexical tokens in a
                //   structured header field are semantically interpreted as a single
                //   space character.
                //
                // is_email() author's note: This *cannot* mean that we must add a
                // space to the address wherever CFWS appears. This would result in
                // any addr-spec that had CFWS outside a quoted string being invalid
                // for RFC 5321.
//                if (($context === ISEMAIL_COMPONENT_LOCALPART) || ($context === ISEMAIL_COMPONENT_DOMAIN)) {
//                    $parsedata[$context]            .= ISEMAIL_STRING_SP;
//                    $atomlist[$context][$element_count]    .= ISEMAIL_STRING_SP;
//                    $element_len++;
//                }

                $i--;    // Look at this token again in the parent context
            }

            $token_prior = $token;
            break;
        //-------------------------------------------------------------
        // A context we aren't expecting
        //-------------------------------------------------------------
        default:
            die("Unknown context: $context");
        }

//-echo "<td>$context|",(($end_or_die) ? 'true' : 'false'),"|$token|" . max($return_status) . "</td></tr>"; // debug
        if ((int) max($return_status) > ISEMAIL_RFC5322) break;    // No point going on if we've got a fatal error
    }

    // Some simple final tests
    if ((int) max($return_status) < ISEMAIL_RFC5322) {
        if    ($context     === ISEMAIL_CONTEXT_QUOTEDSTRING)    $return_status[]    = ISEMAIL_ERR_UNCLOSEDQUOTEDSTR;    // Fatal error
        elseif    ($context     === ISEMAIL_CONTEXT_QUOTEDPAIR)        $return_status[]    = ISEMAIL_ERR_BACKSLASHEND;        // Fatal error
        elseif    ($context     === ISEMAIL_CONTEXT_COMMENT)        $return_status[]    = ISEMAIL_ERR_UNCLOSEDCOMMENT;        // Fatal error
        elseif    ($context     === ISEMAIL_COMPONENT_LITERAL)        $return_status[]    = ISEMAIL_ERR_UNCLOSEDDOMLIT;        // Fatal error
        elseif    ($token        === ISEMAIL_STRING_CR)            $return_status[]    = ISEMAIL_ERR_FWS_CRLF_END;        // Fatal error
        elseif    ($parsedata[ISEMAIL_COMPONENT_DOMAIN]    === '')        $return_status[]    = ISEMAIL_ERR_NODOMAIN;            // Fatal error
        elseif    ($element_len    === 0)                    $return_status[]    = ISEMAIL_ERR_DOT_END;            // Fatal error
        elseif    ($hyphen_flag)                        $return_status[]    = ISEMAIL_ERR_DOMAINHYPHENEND;        // Fatal error
        // http://tools.ietf.org/html/rfc5321#section-4.5.3.1.2
        //   The maximum total length of a domain name or number is 255 octets.
        elseif    (strlen($parsedata[ISEMAIL_COMPONENT_DOMAIN]) > 255)
                                        $return_status[]    = ISEMAIL_RFC5322_DOMAIN_TOOLONG;
        // http://tools.ietf.org/html/rfc5321#section-4.1.2
        //   Forward-path   = Path
        //
        //   Path           = "<" [ A-d-l ":" ] Mailbox ">"
        //
        // http://tools.ietf.org/html/rfc5321#section-4.5.3.1.3
        //   The maximum total length of a reverse-path or forward-path is 256
        //   octets (including the punctuation and element separators).
        //
        // Thus, even without (obsolete) routing information, the Mailbox can
        // only be 254 characters long. This is confirmed by this verified
        // erratum to RFC 3696:
        //
        // http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
        //   However, there is a restriction in RFC 2821 on the length of an
        //   address in MAIL and RCPT commands of 254 characters.  Since addresses
        //   that do not fit in those fields are not normally useful, the upper
        //   limit on address lengths should normally be considered to be 254.
        elseif    (strlen($parsedata[ISEMAIL_COMPONENT_LOCALPART] . ISEMAIL_STRING_AT . $parsedata[ISEMAIL_COMPONENT_DOMAIN]) > 254)
                                        $return_status[]    = ISEMAIL_RFC5322_TOOLONG;
        // http://tools.ietf.org/html/rfc1035#section-2.3.4
        // labels          63 octets or less
        elseif ($element_len > 63)                    $return_status[]    = ISEMAIL_RFC5322_LABEL_TOOLONG;
    }

    // Check DNS?
    $dns_checked = false;

    if ($checkDNS && ((int) max($return_status) < ISEMAIL_DNSWARN) && function_exists('dns_get_record')) {
        // http://tools.ietf.org/html/rfc5321#section-2.3.5
        //   Names that can
        //   be resolved to MX RRs or address (i.e., A or AAAA) RRs (as discussed
        //   in Section 5) are permitted, as are CNAME RRs whose targets can be
        //   resolved, in turn, to MX or address RRs.
        //
        // http://tools.ietf.org/html/rfc5321#section-5.1
        //   The lookup first attempts to locate an MX record associated with the
        //   name.  If a CNAME record is found, the resulting name is processed as
        //   if it were the initial name. ... If an empty list of MXs is returned,
        //   the address is treated as if it was associated with an implicit MX
        //   RR, with a preference of 0, pointing to that host.
        //
        // is_email() author's note: We will regard the existence of a CNAME to be
        // sufficient evidence of the domain's existence. For performance reasons
        // we will not repeat the DNS lookup for the CNAME's target, but we will
        // raise a warning because we didn't immediately find an MX record.
        if ($element_count === 0) $parsedata[ISEMAIL_COMPONENT_DOMAIN] .= '.';        // Checking TLD DNS seems to work only if you explicitly check from the root

        $result = @dns_get_record($parsedata[ISEMAIL_COMPONENT_DOMAIN], DNS_MX);    // Not using checkdnsrr because of a suspected bug in PHP 5.3 (http://bugs.php.net/bug.php?id=51844)

        if ((is_bool($result) && !(bool) $result))
            $return_status[] = ISEMAIL_DNSWARN_NO_RECORD;            // Domain can't be found in DNS
        else {
            if (count($result) === 0) {
                $return_status[]    = ISEMAIL_DNSWARN_NO_MX_RECORD;        // MX-record for domain can't be found
                $result            = @dns_get_record($parsedata[ISEMAIL_COMPONENT_DOMAIN], DNS_A + DNS_CNAME);

                if (count($result) === 0)
                    $return_status[] = ISEMAIL_DNSWARN_NO_RECORD;        // No usable records for the domain can be found
            } else $dns_checked = true;
        }
    }

    // Check for TLD addresses
    // -----------------------
    // TLD addresses are specifically allowed in RFC 5321 but they are
    // unusual to say the least. We will allocate a separate
    // status to these addresses on the basis that they are more likely
    // to be typos than genuine addresses (unless we've already
    // established that the domain does have an MX record)
    //
    // http://tools.ietf.org/html/rfc5321#section-2.3.5
    //   In the case
    //   of a top-level domain used by itself in an email address, a single
    //   string is used without any dots.  This makes the requirement,
    //   described in more detail below, that only fully-qualified domain
    //   names appear in SMTP transactions on the public Internet,
    //   particularly important where top-level domains are involved.
    //
    // TLD format
    // ----------
    // The format of TLDs has changed a number of times. The standards
    // used by IANA have been largely ignored by ICANN, leading to
    // confusion over the standards being followed. These are not defined
    // anywhere, except as a general component of a DNS host name (a label).
    // However, this could potentially lead to 123.123.123.123 being a
    // valid DNS name (rather than an IP address) and thereby creating
    // an ambiguity. The most authoritative statement on TLD formats that
    // the author can find is in a (rejected!) erratum to RFC 1123
    // submitted by John Klensin, the author of RFC 5321:
    //
    // http://www.rfc-editor.org/errata_search.php?rfc=1123&eid=1353
    //   However, a valid host name can never have the dotted-decimal
    //   form #.#.#.#, since this change does not permit the highest-level
    //   component label to start with a digit even if it is not all-numeric.
    if (!$dns_checked && ((int) max($return_status) < ISEMAIL_DNSWARN)) {
        if    ($element_count    === 0)    $return_status[]    = ISEMAIL_RFC5321_TLD;

        if    (is_numeric($atomlist[ISEMAIL_COMPONENT_DOMAIN][$element_count][0]))
                        $return_status[]    = ISEMAIL_RFC5321_TLDNUMERIC;
    }

    $return_status        = array_unique($return_status);
    $final_status        = (int) max($return_status);

    if (count($return_status) !== 1) array_shift($return_status); // remove redundant ISEMAIL_VALID

    $parsedata['status']    = $return_status;

    if ($final_status < $threshold) $final_status = ISEMAIL_VALID;

    return ($diagnose) ? $final_status : ($final_status < ISEMAIL_THRESHOLD);
}
