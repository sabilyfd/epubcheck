Feature: EPUB 3 � Packages Document


  Checks conformance to the "Package document" section of the EPUB 3.3 specification:
    https://www.w3.org/TR/epub-33/#sec-package-doc


  Background:
    Given test files located at '/epub3/05-package-document/files/'
    And EPUBCheck with default settings


  ##  5. Package Document

  Scenario: Verify that the Package Document can have any extension
    When checking EPUB 'package-file-extension-unusual-valid'
    Then no errors or warnings are reported

  # 5.2 Content Conformance

  Scenario: the minimal Package Document is reported as valid 
    When checking file 'minimal.opf'
    Then no errors or warnings are reported
    
  Scenario: a not well-formed Package Document is reported 
    When checking file 'conformance-xml-malformed-error.opf'
    Then fatal error RSC-016 is reported (parsing error)
    And error RSC-005 is reported (schema error)
    And no other errors or warnings are reported
    
  Scenario: using a not-declared namespace is not allowed 
    When checking file 'conformance-xml-undeclared-namespace-error.opf'
    Then fatal error RSC-016 is reported (parsing error)
    And error RSC-005 is reported (schema error)
    And no other errors or warnings are reported


  ## 5.3 Shared attributes
  
  Scenario: 'id' attributes can have leading or trailing space 
    When checking file 'attr-id-with-spaces-valid.opf'
    Then no errors or warnings are reported
  
  Scenario: 'id' attributes must be unique 
    When checking file 'attr-id-duplicate-error.opf'
    Then error RSC-005 is reported 2 times (once for each ID)
    And no other errors or warnings are reported
  
  Scenario: 'id' attributes must be unique after whitespace normalization 
    When checking file 'attr-id-duplicate-with-spaces-error.opf'
    Then error RSC-005 is reported 2 times (once for each ID)
    And no other errors or warnings are reported

  Scenario: the 'dir' attribute value can be 'auto' 
    When checking file 'attr-dir-auto-valid.opf'
    Then no errors or warnings are reported

  Scenario: the 'xml:lang' attribute can be empty
    When checking file 'attr-lang-empty-valid.opf'
    Then no other errors or warnings are reported

  Scenario: the 'xml:lang' language tag must not have leading/trailing whitespace   
    When checking file 'attr-lang-whitespace-error.opf'
    Then error OPF-092 is reported
    And no other errors or warnings are reported

  Scenario: the 'xml:lang' language tag must be well-formed   
    When checking file 'attr-lang-not-well-formed-error.opf'
    Then error OPF-092 is reported
    And no other errors or warnings are reported

  # FIXME does this test really requires a full EPUB?
  Scenario: Verify that three-character language codes are allowed (issue 615)
    When checking EPUB 'package-lang-three-char-code-valid'
    Then no errors or warnings are reported
  

  ## 5.4 The package element

  Scenario: the unique identifier must not be empty
    When checking EPUB 'package-unique-identifier-attribute-missing-error.opf'
    # FIXME OPF-048 could be removed, as it is already reported as RSC-005
    Then the following errors are reported
      | RSC-005 | missing required attribute                       |
      | OPF-048 | missing its required unique-identifier attribute |
    And no other errors or warnings are reported
  
  Scenario: the 'package' 'unique-identifier' attribute must be a known ID
    When checking file 'package-unique-identifier-unknown-error.opf'
    Then error RSC-005 is reported
    And the message contains "does not resolve to a dc:identifier element"
    And no other errors or warnings are reported 
    
  Scenario: the 'package' 'unique-identifier' attribute must point to a 'dc:identifier' element
    When checking file 'package-unique-identifier-not-targeting-identifier-error.opf'
    Then error RSC-005 is reported
    And the message contains "does not resolve to a dc:identifier element"
    And no other errors or warnings are reported 
  
  Scenario: the 'package' element must have a 'metadata' child element  
    When checking file 'package-no-metadata-element-error.opf'
    Then error RSC-005 is reported (missing metadata element)
    And the message contains 'missing required element "metadata"'
    And error RSC-005 is reported (side effect: missing unique-identifier target) 
    And no other errors or warnings are reported
    
  Scenario: the 'package' element's 'metadata' child must be before the 'manifest' child  
    When checking file 'package-manifest-before-metadata-error.opf'
    Then error RSC-005 is reported
    And the message contains 'element "manifest" not allowed yet'
    And error RSC-005 is reported
    And the message contains 'element "metadata" not allowed here' 
    And no other errors or warnings are reported

  
  ## 5.5 Metadata section
  
  ### 5.5.1 The metadata element
  
  ### 5.5.3 Dublin Core required elements
    
  Scenario: 'dc:identifier' must not be empty 
    When checking file 'metadata-identifier-empty-error.opf'
    Then error RSC-005 is reported
    And the message contains "must be a string with length at least 1" 
    And no other errors or warnings are reported
    
 Scenario: 'dc:identifier' starting with "urn:uuid:" should be a valid UUID  
    When checking file 'metadata-identifier-uuid-invalid-warning.opf'
    Then warning OPF-085 is reported
    And no other errors or warnings are reported

 Scenario: 'dc:language' must not be empty  
    When checking file 'metadata-language-empty-error.opf'
    Then error RSC-005 is reported
    And the message contains "must be a string with length at least 1"
    And no other errors or warnings are reported

 Scenario: 'dc:language' must be well-formed  
    When checking file 'metadata-language-not-well-formed-error.opf'
    Then error OPF-092 is reported
    And no other errors or warnings are reported

  Scenario: 'dc:modified' must be defined 
    When checking file 'metadata-modified-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains "dcterms:modified"
    And no other errors or warnings are reported

  Scenario: 'dc:modified' must be of the form 'CCYY-MM-DDThh:mm:ssZ' 
    When checking file 'metadata-modified-syntax-error.opf'
    Then error RSC-005 is reported
    And the message contains "CCYY-MM-DDThh:mm:ssZ"
    And no other errors or warnings are reported

  Scenario: 'dc:title' must be specified
    When checking file 'metadata-title-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'missing required element "dc:title"' 
    And no other errors or warnings are reported

  Scenario: 'dc:title' must not be empty 
    When checking file 'metadata-title-empty-error.opf'
    Then error RSC-005 is reported
    And the message contains "must be a string with length at least 1" 
    And no other errors or warnings are reported
    
  #### 5.5.4 Dublin Core optional elements
  
  Scenario: 'dc:date' can be specified as an ISO 8601:2004 value 
    When checking file 'metadata-date-single-year-valid.opf'
    Then no errors or warnings are reported

  Scenario: 'dc:date' can be specified as a single year 
    When checking file 'metadata-date-single-year-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: 'dc:date' value can have leading/trailng whitespace 
    When checking file 'metadata-date-with-whitespace-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: 'dc:date' with an invalid ISO 8601:2004 syntax is reported
    When checking file 'metadata-date-iso-syntax-error-warning.opf'
    Then warning OPF-053 is reported
    And the message contains "does not follow recommended syntax"
    And no errors or warnings are reported

  Scenario: 'dc:date' with an unknown format is reported
    When checking file 'metadata-date-unknown-format-warning.opf'
    Then warning OPF-053 is reported
    And the message contains "does not follow recommended syntax"
    And no errors or warnings are reported
    
  Scenario: 'dc:source' valid values are allowed 
    When checking file 'metadata-source-valid.opf'
    Then no errors or warnings are reported
  
  Scenario: 'dc:type' valid values are allowed 
    When checking file 'metadata-type-valid.opf'
    Then no errors or warnings are reported
    
  
  #### 5.5.5 The meta element
  
  Scenario: a metadata's property name must be defined 
    When checking file 'metadata-meta-property-empty-error.opf'
    Then error RSC-005 is reported 2 times
    And the message contains 'value of attribute "property" is invalid' 
    And no other errors or warnings are reported
    
  Scenario: a metadata's property name must not be a list of values 
    When checking file 'metadata-meta-property-list-error.opf'
    Then error RSC-005 is reported (value is not an NMTOKEN)
    Then error OPF-025 is reported
    And the message contains "only one value must be specified"
    And no other errors or warnings are reported

  Scenario: a metadata's property name must be well-formed
    When checking file 'metadata-meta-property-malformed-error.opf'
    Then error OPF-026 is reported
    And no other errors or warnings are reported
    
  Scenario: a metadata's value must be defined 
    When checking file 'metadata-meta-value-empty-error.opf'
    Then error RSC-005 is reported
    And the message contains "must be a string with length at least 1" 
    And no other errors or warnings are reported

  Scenario: 'refines' attribute MUST be a relative URL 
    When checking file 'metadata-refines-not-relative-error.opf'
    Then error RSC-005 is reported
    And the message contains "@refines must be a relative URL"
    And no other errors or warnings are reported

  Scenario: 'refines' attribute should use a fragment ID if refering to a Publication Resource 
    When checking file 'metadata-refines-not-a-fragment-warning.opf'
    Then warning RSC-017 is reported
    And the message contains "using a fragment identifier pointing to its manifest item"
    And no other errors or warnings are reported

  Scenario: 'refines' attribute, when using fragment ID, must target an existing ID
    When checking file 'metadata-refines-unknown-id-error.opf'
    Then error RSC-005 is reported
    And the message contains "@refines missing target id"
    And no other errors or warnings are reported
    
  Scenario: 'refines' references cycles are not allowed
    When checking file 'metadata-refines-cycle-error.opf'
    Then error OPF-065 is reported
    And no other errors or warnings are reported
    
  Scenario: 'scheme' can be used to identify the value system
    When checking file 'metadata-meta-scheme-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: 'scheme' must not be list of values
    When checking file 'metadata-meta-scheme-list-error.opf'
    Then error RSC-005 is reported (value is not an NMTOKEN)
    And error OPF-025 is reported
    And no other errors or warnings are reported
    
  Scenario: 'scheme' must not be an unknown value with no prefix
    When checking file 'metadata-meta-scheme-unknown-error.opf'
    Then error OPF-027 is reported
    And no other errors or warnings are reported
  

  #### 5.5.7 The link element
  
  Scenario: 'link' targets must not be manifest items 
    When checking file 'link-to-publication-resource-error.opf'
    Then error OPF-067 is reported
    And no other errors or warnings are reported

  Scenario: the 'link' element can have an 'hreflang' attribute
    When checking file 'link-hreflang-valid.opf'
    Then no other errors or warnings are reported

  Scenario: the 'link' 'hreflang' attribute can be empty
    When checking file 'link-hreflang-empty-valid.opf'
    Then no other errors or warnings are reported

  Scenario: the 'link' 'hreflang' language tag must not have leading/trailing whitespace   
    When checking file 'link-hreflang-whitespace-error.opf'
    Then error OPF-092 is reported
    And no other errors or warnings are reported

  Scenario: the 'link' 'hreflang' language tag must be well-formed   
    When checking file 'link-hreflang-not-well-formed-error.opf'
    Then error OPF-092 is reported
    And no other errors or warnings are reported

  Scenario: Report a package metadata link to a missing resource
    When checking EPUB 'package-link-missing-resource-error'
    Then warning RSC-007w is reported
    And no other errors or warnings are reported
  
  
  ### 5.6 Manifest section
  
  ### 5.6.1 The manifest element

  @spec @xref:sec-manifest-elem
  Scenario: Report a remote image declared in the package document when it is referenced from an HTML `a` element
    When checking EPUB 'package-remote-img-in-link-error'
    Then error RSC-006 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-manifest-elem
  Scenario: Report remote audio resources not declared in the package document
    When checking EPUB 'package-remote-audio-undeclared-error'
    Then error RSC-008 is reported
    And error MED-002 is reported (side-effect error about the audio missing a fallback, since its type cannot be known from the OPF declaration)
    And no other errors or warnings are reported

  @spec @xref:sec-manifest-elem
  Scenario: Report remote audio resources defined in `sources` elements but not declared in the package document
    When checking EPUB 'package-remote-audio-sources-undeclared-error'
    Then error RSC-008 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-manifest-elem
  Scenario: Report a remote font not declared in the package document
    When checking EPUB 'package-remote-font-undeclared-error'
    Then error RSC-008 is reported
    And no other errors or warnings are reported
  
  
  ### 5.6.2.1 Resource properties
  
  Scenario: An unknown item property in the default vocab is reported
    When checking file 'item-property-unknown-error.opf'
    Then error OPF-027 is reported
    And no errors or warnings are reported
  
  ## cover-image
  
  @spec @xref:sec-item-resource-properties
  Scenario: The 'cover-image' item property must occur at most once 
    When checking file 'item-property-cover-image-multiple-error.opf'
    Then error RSC-005 is reported
    And the message contains "cover-image"
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: The 'cover-image' item property must only be used on images 
    When checking file 'item-property-cover-image-wrongtype-error.opf'
    Then error OPF-012 is reported
    And no other errors or warnings are reported
  
  @spec @xref:sec-item-resource-properties
  Scenario: Report an unknown manifest item property
    When checking EPUB 'package-manifest-prop-unknown-error'
    Then error OPF-027 is reported
    And no other errors or warnings are reported

  ###  mathml

  @spec @xref:sec-item-resource-properties
  Scenario: Verify content documents are identified as containing mathml
    When checking EPUB 'package-mathml-valid'
    Then no errors or warnings are reported    

  ###  remote-resources

  @spec @xref:sec-item-resource-properties
  Scenario: Report an XHTML document with remote audio but without the `remote-resources` property set in the package document
    When checking EPUB 'package-remote-audio-missing-property-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report remote fonts in CSS without the `remote-resource` property set in the package document
    When checking EPUB 'package-remote-font-in-css-missing-property-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report an SVG using remote fonts without the `remote-resource` property set in the package document
    When checking EPUB 'package-remote-font-in-svg-missing-property-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report an XHTML document using remote fonts in `style` without the `remote-resource` property set in the package document
    When checking EPUB 'package-remote-font-in-xhtml-missing-property-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported
  
  @spec @xref:sec-item-resource-properties
  Scenario: Report the declaration of the `remote-resources` property when the content has no script
    When checking EPUB 'package-manifest-prop-remote-resource-declared-but-unnecessary-error'
    Then warning OPF-018 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report a reference a remote resource when the `remote-resources` property is not set in the manifest
    When checking EPUB 'package-manifest-prop-remote-resource-undeclared-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report the incorrect use of the `remote-resources` property for a resource defined in an `object` `param` element (issue 249)
    When checking EPUB 'package-manifest-prop-remote-resource-object-param-warning'
    Then warning OPF-018 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report a media overlay document with remote resources but missing the `remote-resources` property
    When checking EPUB 'package-remote-audio-in-overlays-missing-property-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  ###  scripted

  @spec @xref:sec-item-resource-properties
  Scenario: Report the declaration of the `scripted` property when the content has no script
    When checking EPUB 'package-manifest-prop-scripted-declared-but-unnecessary-error'
    Then error OPF-015 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report a scripted document without the `scripted` property declared in the package document
    When checking EPUB 'package-manifest-prop-scripted-undeclared-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Verify that script data blocks do not require the `scripted` property to be defined in the manifest
    When checking EPUB 'package-manifest-prop-scripted-not-required-for-script-data-block-valid'
    Then no errors or warnings are reported

  ###  svg

  @spec @xref:sec-item-resource-properties
  Scenario: Report the declaration of the `svg` property when the content has no embedded SVG
    When checking EPUB 'package-manifest-prop-svg-declared-but-unnecessary-error'
    Then error OPF-015 is reported
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report references to embedded SVG when the `svg` property is not set in the manifest 
    When checking EPUB 'package-manifest-prop-svg-undeclared-error'
    Then error OPF-014 is reported 2 times
    And no other errors or warnings are reported

  @spec @xref:sec-item-resource-properties
  Scenario: Report reference to an embedded SVG when the `svg` property is not set in the manifest (one reference is set properly)
    When checking EPUB 'package-manifest-prop-svg-undeclared-partial-error'
    Then error OPF-014 is reported
    And no other errors or warnings are reported


  ###  switch

  @spec @xref:sec-item-resource-properties
  Scenario: Report a content document without the `switch` property declared in the manifest
    When checking EPUB 'package-manifest-prop-switch-not-declared-error'
    Then error OPF-014 is reported
    And warning RSC-017 is reported
    And the message contains 'The "epub:switch" element is deprecated'
    And no other errors or warnings are reported


  #### 5.6.2 The item element
  
  Scenario: a manifest item must declare a media type  
    When checking file 'item-media-type-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'missing required attribute "media-type"'
    And no other errors or warnings are reported

  Scenario: item URLs should not contain spaces, even if properly encoded
    When checking file 'item-href-contains-spaces-unencoded-error.opf'
    Then error RSC-020 is reported
    And warning PKG-010 is reported (side effect of spaces)
    And no other errors or warnings are reported

  Scenario: item URLs should not contain spaces, even if properly encoded
    When checking file 'item-href-contains-spaces-warning.opf'
    Then warning PKG-010 is reported
    And no other errors or warnings are reported

  Scenario: item URLs must not have a fragment identifier
    When checking file 'item-href-with-fragment-error.opf'
    Then error OPF-091 is reported
    And no other errors or warnings are reported

  Scenario: two manifest items cannot represent the same resource 
    When checking file 'item-duplicate-resource-error.opf'
    Then error OPF-074 is reported
    And no other errors or warnings are reported
  
  Scenario: one item must have the 'nav' property  
    When checking file 'item-nav-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Exactly one manifest item must declare the "nav" property'
    And no other errors or warnings are reported
    
  Scenario: at most one item must have the 'nav' property  
    When checking file 'item-nav-multiple-error.opf'
    Then error RSC-005 is reported
    And the message contains 'Exactly one manifest item must declare the "nav" property'
    And no other errors or warnings are reported
    
  Scenario: the 'nav' property must be on an XHTML Content Document  
    When checking file 'item-nav-not-xhtml-error.opf'
    Then error RSC-005 is reported
    And the message contains 'the Navigation Document must be of the "application/xhtml+xml" type'
    And error OPF-012 is reported ('nav' undefined for 'application/x+dtbncx+xml')
    And no other errors or warnings are reported

  Scenario: Report duplicate declarations of a resource in the package document manifest
    When checking EPUB 'package-manifest-duplicate-resource-error'
    Then error OPF-074 is reported
    And no other errors or warnings are reported

  Scenario: Report a resource declared in the package document but missing from the container
    When checking EPUB 'package-manifest-item-missing-error'
    Then error RSC-001 is reported
    And no other errors or warnings are reported

  Scenario: Report a manifest item path with unencoded spaces
    See issue #239 for why this needs to also be checked at the publication level
    When checking file 'package-manifest-item-with-spaces-warning'
    Then warning PKG-010 is reported
    And no other errors or warnings are reported

  Scenario: Report fonts declared in the package document but missing from the container
    When checking EPUB 'package-manifest-fonts-missing-error'
    Then error RSC-001 is reported 3 times
    And no other errors or warnings are reported
  
  Scenario: fallback attribute must point to an existing item ID 
    When checking file 'fallback-to-unknown-id-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must resolve to another manifest item'
    And no other errors or warnings are reported
    
  Scenario: fallback attribute must not reference its item ID 
    When checking file 'fallback-to-self-error.opf'
    Then error RSC-005 is reported
    And the message contains 'must resolve to another manifest item'
    And no other errors or warnings are reported

  Scenario: Report a manifest fallback that references a non-existent resource
    When checking EPUB 'package-manifest-fallback-non-resolving-error'
    Then error RSC-005 is reported
    And the message contains 'manifest item element fallback attribute must resolve to another manifest item'
    And error MED-003 is reported
    And no other errors or warnings are reported
    
  Scenario: Report usage of the EPUB 2 'fallback-style' attribute
    When checking file 'fallback-style-error.opf'
    Then error RSC-005 is reported
    And the message contains 'fallback-style'
    And no other errors or warnings are reported

  #### 5.6.3 The bindings Element
  
  Scenario: Report usage of the 'bindings' element as deprecated 
    When checking file 'bindings-deprecated-warning.opf'
    Then warning RSC-017 is reported
    And no other errors or warnings are reported

  Scenario: Report a binding declared for an image resource
    When checking file 'bindings-for-image-error.opf'
    Then warning RSC-017 is reported (since bindings is deprecated)
    And error OPF-008 is reported (to report handler for an image)
    And no other errors or warnings are reported

  Scenario: Report a bindings handler that is not an XHTML Content Document
    When checking file 'bindings-handler-not-xhtml-error.opf'
    Then warning RSC-017 is reported (since bindings is deprecated)
    And error RSC-005 is reported (to report the non-XHTML handler)
    And no other errors or warnings are reported

  Scenario: Report a bindings handler for a type that already has a handler
    When checking file 'package-bindings-handler-duplicate-error'
    Then warning RSC-017 is reported (since bindings is deprecated)
    And error OPF-009 is reported (to report the duplicate handler)
    And no other errors or warnings are reported

  Scenario: Report a bindings handler that is not a scripted document
    When checking file 'package-bindings-handler-not-scripted-error'
    Then warning RSC-017 is reported (since bindings is deprecated)
    And error OPF-046 is reported (to report the duplicate handler)
    And no other errors or warnings are reported
  
  ### 5.7 Spine section
  
  #### 5.7.1 The spine element

  Scenario: Report a missing spine
    When checking EPUB 'package-spine-missing-error'
    Then the following errors are reported
      | RSC-005 | missing required element "spine"                 |
      | RSC-011 | reference to a resource that is not a spine item | # in the Nav Doc
    And no other errors or warnings are reported

  #### 5.7.2 The itemref element
  
  Scenario: An SVG Content Document is allowed in the spine 
    When checking file 'spine-item-svg-valid.opf'
    Then no errors or warnings are reported
    
  Scenario: An unknown 'itemref' ID is reported  
    When checking file 'spine-item-unknown-error.opf'
    Then error OPF-049 is reported (ID not found)
    Then error RSC-005 is reported (schema error)
    And no other errors or warnings are reported

  Scenario: Two spine 'itemref' elements cannot reference the same manifest item  
    When checking file 'spine-item-duplicate-error.opf'
    Then error RSC-005 is reported
    And the message contains "Itemref refers to the same manifest entry as a previous itemref"
    And no other errors or warnings are reported


  ## 5.8 Collections
  
  ### 5.8.1 The collection element

  Scenario: a collection role can be an absolute URL
    When checking file 'collection-role-url-valid.opf'
    Then no errors or warnings are reported

  Scenario: a collection role must not be an invalid URL
    Spec mismatch: this should be reported as an error 
    When checking file 'collection-role-url-invalid-error.opf'
    Then warning OPF-070 is reported
    And no other errors or warnings are reported

  Scenario: a collection role URL cannot contain 'idpf.org' in its host 
    When checking file 'collection-role-url-idpf.org-error.opf'
    Then error OPF-069 is reported
    And no other errors or warnings are reported

  Scenario: a collection role must not be an unknown token value
    When checking file 'collection-role-unknown-error.opf'
    Then error OPF-068 is reported
    And no other errors or warnings are reported

  Scenario: a 'manifest' collection must be the child of another collection
    See http://idpf.org/epub/vocab/package/roles/manifest/
    When checking file 'collection-role-manifest-toplevel-error.opf'
    Then error RSC-005 is reported
    And the message contains "A manifest collection must be the child of another collection"
    And no other errors or warnings are reported

  ## 5.9 Legacy content
  
  #### 5.9.1 The meta element
  
  #### 5.9.2 The guide element

  Scenario: 'guide' should not contain two entries of the same type pointing to the same resource
    When checking EPUB 'legacy-guide-duplicates-warning.opf'
    Then warning RSC-017 is reported 2 times (once for each entry)
    And the message contains 'Duplicate "reference" elements with the same "type" and "href" attributes'
    And no other errors or warnings are reported
    
  #### 5.9.3 NCX

  Scenario: When an NCX document is present, it must be identified in the 'toc' attribute of the spine  
    When checking file 'legacy-ncx-toc-attribute-missing-error.opf'
    Then error RSC-005 is reported
    And the message contains "toc attribute must be set"
    And no other errors or warnings are reported
    
  Scenario: The 'toc' attribute of the spine must point to an NCX document  
    When checking file 'legacy-ncx-toc-attribute-not-ncx-error.opf'
    Then error OPF-050 is reported
    Then error RSC-005 is reported (duplicate schema error)
    And no other errors or warnings are reported

  Scenario: Verify a publication featuring a legacy NCX navigation document
    When checking EPUB 'package-ncx-valid'
    Then no errors or warnings are reported

  Scenario: Report validation errors in legacy NCX documents
    When checking EPUB 'package-ncx-invalid-error'
    Then error RSC-012 is reported
    And the message contains 'Fragment identifier is not defined'
    And no other errors or warnings are reported

  Scenario: Verify an NCX which does not link to all spine items
    Given the reporting level set to USAGE
    When checking EPUB 'package-ncx-missing-references-to-spine-valid'
    Then no errors or warnings are reported
