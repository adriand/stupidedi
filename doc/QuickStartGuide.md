# Quick Start Guide

Last updated: March 2025.

## Introduction To EDI

A full explanation of EDI is beyond the scope of this documentation, but here we attempt an overview, which we will tie into the specific functionality that Stupidedi offers. (If you are already well-versed in EDI, you may want to skip to the [XXXX] SECTION)

EDI (Electronic Data Interchange) is a standardized method for organizations to exchange business documents electronically in a structured, machine-readable format. Instead of paper-based exchanges or non-standardized electronic communications, EDI allows computer systems to communicate directly with each other using agreed-upon formats.

### Key Concepts

**Standardized Format**: EDI replaces paper documents with standardized electronic formats that follow specific rules for structure and content.

**Business Documents**: Common EDI documents include purchase orders, invoices, shipping notices, healthcare claims, and payment instructions.

**Trading Partners**: Organizations that exchange EDI documents with each other (buyers/sellers, providers/payers, etc.) are considered trading partners. In EDI, trading partner information is contained in the interchange header (the beginning portion of the document), and can be considered similar to the header information contained within emails, like the sender and receiver.

**Standards Organizations**: Bodies like X12 (primarily North America) and EDIFACT (international) define and maintain EDI standards. At the time of writing, Stupidedi does not support EDIFACT.

**Communication Methods**: Various networks and protocols are used to transmit EDI documents (VAN, AS2, SFTP, etc.) Stupidedi does not provide functionality for dealing with EDI communications.

### The 990 Response To Load Tender

To illustrate some of the concepts you need to understand and to build a foundation that will enable you to use Stupidedi effectively, we now turn our attention to a particular kind of EDI document, specifically, the **GF 990 Response To Load Tender** (referred to as "the 990" going forward) as defined in the 00401 release.

The 990 is common in logistics. Consider a carrier, i.e. a logistics company that moves freight from point A to point B for its customers. We will call this carrier Acme Trucking.

Acme Trucking has a customer, Waldo Mart, who needs freight moved. Waldo Mart needs to move a lot of freight, and would like to be able to tell Acme Trucking about it without needing to pick up the phone and call someone there. In other words, they would like to automate their operations, which they will do by establishing a trading partner relationship and using EDI to exchange key documents.

To tell Acme Trucking that it needs a shipment picked up and carried from a warehouse to a distributor, Waldo Mart transmits an SM 204 Motor Carrier Load Tender EDI document to Acme Trucking. This document contains all the information that Acme Trucking needs to determine if they are willing and able to carry the shipment: where it needs to get picked up, where it is going, how much it weighs, how much Waldo Mart is willing to pay for the service, and so on.

Once Acme Trucking has reviewed the information and decided whether or not they wish to carry the shipment, they reply to Waldo Mart by sending them the 990. The 990's key role is to tell Waldo Mart whether or not Acme Trucking has accepted or declined the shipment. Here is an example EDI document that does exactly that.

```
ISA*00*          *00*          *12*ACME           *14*WALDO          *250303*1506*U*00401*000000052*0*P*:~
GS*GF*ACME*WALDO          *20250303*1506*52*X*004010~
ST*990*00000052~
B1*ACME*339807*20220802*A~
N9*CN*ACM12345~
SE*4*00000052~
GE*1*52~
IEA*1*000000052~
```

The key information is contained within this line:

`B1*ACME*339807*20220802*A~`

Let's break this down bit-by-bit.

First of all, although our example EDI file's lines are separated by carriage return characters, many EDI documents are not separated, and may arrive with no formatting whatsoever. Each line is, instead, delineated by a character. In this particular EDI file, that character is the tilde (~). However, this can vary.

The line begins with B1. B1 identifies a segment, and it means "Beginning Segment for Booking or Pick-up/Delivery".

How do we know this? After all, nowhere in the document do the words "Beginning Segment for Booking or Pick-up/Delivery" appear.

This question is at the heart of what makes EDI more challenging than more modern document transmission formats such as XML or JSON. Much of the meaningful information contained within an EDI file is not contained within the file at all, but appears in other documents:

The _X12 release_ (basically a numbered versioning system) contains definitions for thousands of segments. This particular EDI file's release version is 00401. X12 00401 defines what B1 means within the context of the _transaction set_: the specific kind of document we are dealing with (in this case, the 990).

The _implementation_ is how a given trading partner has decided to use, or _implement_, the X12 release's transaction set specification. You can think of the X12 release's specification as the make and model of a car, and the implementation as the colour and trim. Or to use more technical terminology, the release defines a schema, and the implementation is a subset of that schema.

A trading partner typically communicates the details of their implementation in a document that is often referred to as a _guide_.

Back to our example. We now know that this line:

`B1*ACME*339807*20220802*A~`

Contains the key information about whether or not Acme Trucking has agreed to deliver this shipment. Earlier we saw that the entire file is split into lines using tildes. Each line is split into _elements_. In this case, the elements are separated by asterisks (\*).

As such, this line contains four elements. Using the typical labelling scheme, these are written out as:

B1-01: ACME
B1-02: 339807
B1-03: 20220802
B1-04: A

Just like the X12 specification defines what B1 means, so it also defines what each element within B1 means. The fourth element in B1, B1-04, is the "Reservation Action Code". Here, we see an "A".

Once again - you should be picking up on this pattern now - the meaning of "A" is also defined in the X12 specification. In this context, an "A" means "Reservation Accepted". In other words, Acme Trucking said "yes, we'll take it". A "D" in B1-04, on the other hand, means "Reservation Cancelled": i.e. "no thanks".

### So Why Is A Tool Needed?

After this explanation, you might be wondering why a tool like Stupidedi is necessary. For instance, if we wanted to figure out if a 990 indicated an acceptance (A) or cancellation (D), it would not be difficult to open up the file, split it by tildes, look for the line that starts with B1, read the last character, and so on.

Many programmers have surely started down this path and learned difficult lessons in the process. Here's why this is a bad idea.

First, we have deliberately selected a very simple example. Most EDI documents are more complex than the 990, and some run to hundreds of lines.

Second, many segment types appear more than once. There is a single N9 in this document, but it is not unusual for dozens of N9s to appear in a single document. The meaning of each of those N9s can be completely different, depending on where they are.

Third, X12 EDI documents support structures that we have not discussed, such as loops, which are conceptually similar to arrays. Whereas formats like XML and JSON include array-definition syntax (i.e. `item: ['a', 'b']`), EDI documents do not. Whether or not a loop can appear in a given location in the document is defined in - you guessed it - the X12 specification.

Due to subtleties which are beyond the scope of this guide, it is not even possible to tell when a loop ends without reference to the specification.

What this means is that reading (parsing) and writing (generating) EDI documents requires the tool to include a representation of both the specification _and_ the implementation.

Fortunately for you, Stupidedi includes a sophisticated and battle-tested aproach to these challenges.

In the remainder of this guide, we will take on roles at each of the companies we have been using as our examples. We will start as a software developer at Waldo Mart writing code to determine if Acme Trucking has agreed to move our shipment or not. Then we will switch roles and head to Acme Trucking, where we will learn how to generate the 990s that we're sending to Waldo Mart.

XXXXXXXXX HERE WE ARE XXXXXXXXXX

### Parsing The 990

### Generating The 990

### Terminology

**Release**: X12 releases refer to the published versions of the X12 standards that are issued periodically by the X12 organization. Each release contains updates, corrections, and new functionality. Releases are identified by version numbers and are published on a scheduled basis to support evolving business requirements. Stupidedi covers a limited set of X12 releases (at the time of this writing in early 2025, supported releases include 00200, 00300, 00400, 00401 and 00501).

**Transaction set**: A transaction set in X12 EDI is a complete business document exchanged between trading partners. It's the electronic equivalent of a paper business document like a purchase order, invoice, or healthcare claim.

**Standard**: X12 standards are the formal specifications that define the structure, format, and content of transactions. These standards specify the exact format for various transaction sets (e.g., 837 for healthcare claims, 850 for purchase orders), including segment definitions, data element requirements, and syntax rules. The standards ensure that trading partners can exchange business documents in a consistent, predictable manner.

- Implementations

### Overview Of Stupidedi

## Getting Started

### The 990

- What it's for
- The standard
- Example implementation (guide)

### Parsing

- Opening up an EDI file
- Navigating through it
- Extracting data
- Extracting all data (e.g. translating to JSON)

### Generating

### Defining
