Feature: EPUB 3 — Vocabularies


  Checks conformance to the "Vocabularies" section of the EPUB 3.3 specification:
    https://www.w3.org/TR/epub-33/#app-vocabs


  Background: 
    Given EPUB test files located at '/epub3/D-vocabularies/files/'
    And EPUBCheck with default settings

  # C. Meta Properties Vocabulary

  Scenario: 'authority' metadata can refine a subject expression
  	When checking file 'metadata-meta-authority-valid.opf'
  	Then no errors or warnings are reported

  Scenario: 'authority' metadata can only refine a subject expression
  	When checking file 'metadata-meta-authority-refines-disallowed-error.opf'
  	Then error RSC-005 is reported
    And the message contains 'Property "authority" must refine a "subject" property'
  	Then no errors or warnings are reported

  Scenario: 'authority' metadata must be associated to a term
  	When checking file 'metadata-meta-authority-no-term-error.opf'
  	Then error RSC-005 is reported
  	And the message contains "A term property must be associated"
  	And no other errors or warnings are reported

  Scenario: 'authority' metadata must not be defined more than once
  	When checking file 'metadata-meta-authority-cardinality-error.opf'
  	Then error RSC-005 is reported
  	And the message contains "Only one pair of authority and term properties"
  	And no other errors or warnings are reported

  Scenario: 'belongs-to-collection' metadata can identify the publicationâ€™s collection
    When checking file 'metadata-meta-collection-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'belongs-to-collection' metadata can only refine other 'belongs-to-collection' metadata
    When checking file 'metadata-meta-collection-refines-non-collection-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Property "belongs-to-collection" can only refine other "belongs-to-collection" properties'
    And no other errors or warnings are reported

  Scenario: 'collection-type' cannot be used as a primary metadata
    When checking file 'metadata-meta-collection-type-refines-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Property "collection-type" must refine a "belongs-to-collection" property'
    And no other errors or warnings are reported

  Scenario: 'collection-type' metadata can only refine a 'belongs-to-collection' property
    When checking file 'metadata-meta-collection-type-refines-non-collection-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Property "collection-type" must refine a "belongs-to-collection" property'
    And no other errors or warnings are reported

  Scenario: 'collection-type' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-collection-type-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"collection-type" cannot be declared more than once'
    And no other errors or warnings are reported
  
  Scenario: 'display-seq' metadata is allowed 
    When checking file 'metadata-meta-display-seq-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'display-seq' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-display-seq-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"display-seq" cannot be declared more than once'
    And no other errors or warnings are reported
  
  Scenario: 'file-as' metadata is allowed 
    When checking file 'metadata-meta-file-as-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'file-as' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-file-as-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"file-as" cannot be declared more than once'
    And no other errors or warnings are reported

  Scenario: 'group-position' metadata is allowed 
    When checking file 'metadata-meta-group-position-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'group-position' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-group-position-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"group-position" cannot be declared more than once'
    And no other errors or warnings are reported

	Scenario: 'identifier-type' metadata can only refine a 'source' or 'identifier' property
    When checking file 'metadata-meta-identifier-type-refines-disallowed-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Property "identifier-type" must refine an "identifier" or "source" property'
    And no other errors or warnings are reported
    
  Scenario: 'identifier-type' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-identifier-type-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"identifier-type" cannot be declared more than once'
    And no other errors or warnings are reported
    
  Scenario: 'meta-auth' metadata is deprecated 
    When checking file 'metadata-meta-meta-auth-deprecated-warning.opf'
    Then warning RSC-017 is reported
    And the message contains "the meta-auth property is deprecated"
    And no other errors or warnings are reported

  Scenario: 'role' metadata can be used once or more to refine a creator, contributor, or publisher 
    When checking file 'metadata-meta-role-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'role' metadata cannot be used to refine properties other than creator, contributor, or publisher  
    When checking file 'metadata-meta-role-refines-disallowed-error.opf'
    Then error RSC-005 is reported
    And the message contains '"role" must refine a "creator", "contributor", or "publisher" property'
    And no other errors or warnings are reported
  
  Scenario: 'source-of' metadata can be used to refine the pagination source 
    When checking file 'metadata-meta-source-of-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: 'source-of' metadata value must be "pagination" 
    When checking file 'metadata-meta-source-of-value-unknown-error.opf'
    Then error RSC-005 is reported
    And the message contains 'The "source-of" property must have the value "pagination"'
    And no other errors or warnings are reported
  
  Scenario: 'source-of' metadata cannot be used as a primary metadata 
    When checking file 'metadata-meta-source-of-refines-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'The "source-of" property must refine a "source" property'
    And no other errors or warnings are reported
  
  Scenario: 'source-of' metadata must refine a 'dc:source' metadata entry
    When checking file 'metadata-meta-source-of-refines-not-dcsource-error.opf'
    Then error RSC-005 is reported
    And the message contains 'The "source-of" property must refine a "source" property'
    And no other errors or warnings are reported

  Scenario: 'source-of' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-source-of-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"source-of" cannot be declared more than once'
    And no other errors or warnings are reported

  Scenario: 'term' metadata can refine a subject expression
  	When checking file 'metadata-meta-term-valid.opf'
  	Then no errors or warnings are reported

  Scenario: 'term' metadata can only refine a subject expression
  	When checking file 'metadata-meta-term-refines-disallowed-error.opf'
  	Then error RSC-005 is reported
    And the message contains 'Property "term" must refine a "subject" property'
  	Then no errors or warnings are reported

  Scenario: 'term' metadata must be associated to an authority
  	When checking file 'metadata-meta-term-no-authority-error.opf'
  	Then error RSC-005 is reported
  	And the message contains "An authority property must be associated"
  	And no other errors or warnings are reported

  Scenario: 'term' metadata must not be defined more than once
  	When checking file 'metadata-meta-term-cardinality-error.opf'
  	Then error RSC-005 is reported
  	And the message contains "Only one pair of authority and term properties"
  	And no other errors or warnings are reported

  Scenario: 'title-type' metadata can be used to refine a title expression 
    When checking file 'metadata-meta-title-type-valid.opf'
    Then no errors or warnings are reported

	Scenario: 'title-type' metadata can only refine a 'title' expression
    When checking file 'metadata-meta-title-type-refines-disallowed-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Property "title-type" must refine a "title" property'
    And no other errors or warnings are reported

  Scenario: 'title-type' metadata cannot be defined more than once to refine the same expression 
    When checking file 'metadata-meta-title-type-cardinality-error.opf'
    Then error RSC-005 is reported
    And the message contains '"title-type" cannot be declared more than once'
    And no other errors or warnings are reported
  
  # D. Metadata Link Vocabulary
  
  Scenario: the link 'rel' attribute can have multiple properties
    When checking file 'link-rel-multiple-properties-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: an 'acquire' link can identify the full version of the publication
    When checking file 'link-rel-acquire-valid.opf'
    Then no errors or warnings are reported

  Scenario: an 'alternate' link can identify an alternate version of the Package Document
    When checking file 'link-rel-alternate-valid.opf'
    Then no errors or warnings are reported

  Scenario: an 'alternate' link must not be paired with other keywords
    When checking file 'link-rel-alternate-with-other-keyword-error.opf'
    Then error OPF-089 is reported
    And no other errors or warnings are reported

  Scenario: a 'record' link can point to a local record
    When checking file 'link-rel-record-local-valid.opf'
    Then no errors or warnings are reported

  Scenario: a 'record' link can point to a remote record
    When checking file 'link-rel-record-remote-valid.opf'
    Then no errors or warnings are reported

    
  Scenario: 'record' link can be paired with other keywords
    When checking file 'link-rel-record-with-other-keyword-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: a 'record' link must have a 'media-type' attribute 
    When checking file 'link-rel-record-mediatype-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains "media-type"
    And no other errors or warnings are reported

  Scenario: a 'record' link type can be further identified with a 'properties' attribute
    When checking file 'link-rel-record-properties-valid.opf'
    And no errors or warnings are reported

  Scenario: a 'record' link with an unknown identifier property is reported
    When checking file 'link-rel-record-properties-undefined-error.opf'
    Then error OPF-027 is reported
    And no other errors or warnings are reported
    
  Scenario: a 'record' link with an empty identifier property is reported
    When checking file 'link-rel-record-properties-empty-error.opf'
    Then error RSC-005 is reported
    And the message contains 'value of attribute "properties" is invalid'
    And no other errors or warnings are reported

  Scenario: a 'record' link cannot refine another property or resource
    When checking file 'link-rel-record-refines-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must not have a "refines" attribute'
    And no other errors or warnings are reported

  Scenario: '*-record' links are deprecated 
    When checking file 'link-rel-record-deprecated-warning.opf'
    Then the following warnings are reported
      | OPF-086 | "marc21xml-record" is deprecated |
      | OPF-086 | "mods-record" is deprecated      |
      | OPF-086 | "onix-record" is deprecated      |
      | OPF-086 | "xmp-record" is deprecated       |
    And no other errors or warnings are reported
    
  Scenario: a 'voicing' link can identify the aural representation of metadata
    When checking file 'link-rel-voicing-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: a 'voicing' link must refine another property or resource
    When checking file 'link-rel-voicing-as-publication-metadata-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must have a "refines" attribute'
    And no other errors or warnings are reported

  Scenario: a 'voicing' link must have a 'media-type' attribute
    When checking file 'link-rel-voicing-mediatype-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must have a "media-type" attribute'
    And no other errors or warnings are reported

  Scenario: a 'voicing' link resource must have an audio media type
    When checking file 'link-rel-voicing-mediatype-not-audio-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must have a "media-type" attribute identifying an audio MIME type'
    And no other errors or warnings are reported
    
  Scenario: 'xml-signature' links are deprecated 
    When checking file 'link-rel-xml-signature-deprecated-warning.opf'
    Then warning OPF-086 is reported
    And the message contains '"xml-signature" is deprecated'
    And no other errors or warnings are reported
