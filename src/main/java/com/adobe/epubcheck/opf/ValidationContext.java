package com.adobe.epubcheck.opf;

import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;

import org.w3c.epubcheck.core.Checker;

import com.adobe.epubcheck.api.EPUBProfile;
import com.adobe.epubcheck.api.FeatureReport;
import com.adobe.epubcheck.api.LocalizableReport;
import com.adobe.epubcheck.api.Report;
import com.adobe.epubcheck.ocf.OCFPackage;
import com.adobe.epubcheck.overlay.OverlayTextChecker;
import com.adobe.epubcheck.util.EPUBVersion;
import com.adobe.epubcheck.util.GenericResourceProvider;
import com.adobe.epubcheck.vocab.Property;
import com.google.common.base.MoreObjects;
import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import com.google.common.base.Predicate;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableSet;
import com.google.common.collect.Sets;

/**
 * Holds various contextual objects used during validation. This validation
 * context is notalby used by {@link Checker} instances.
 * 
 */
public final class ValidationContext
{
  /**
   * The path to the validated resource. Guaranteed non-null.
   */
  public final String path;
  /**
   * The media type of the validated resource. Guaranteed non-null.
   */
  public final String mimeType;
  /**
   * The EPUB version being used for validation. Guaranteed non-null.
   */
  public final EPUBVersion version;
  /**
   * The validation profile in use (e.g. DEFAULT, EDUPUB, etc.). Guaranteed
   * non-null.
   */
  public final EPUBProfile profile;
  /**
   * The report object used to log validation messages. Guaranteed non-null.
   */
  public final Report report;
  /**
   * The locale used to log validation messages. Guaranteed non-null.
   */
  public final Locale locale;
  /**
   * Used to report some features of the validated resource, without logging.
   * Guaranteed non-null.
   */
  public final FeatureReport featureReport;

  /**
   * Used to open resource streams. Guaranteed non-null.
   */
  public final GenericResourceProvider resourceProvider;
  /**
   * The Package Document item for the validated resource. Is absent if there is
   * no item representing this resource in the Package Document.
   */
  public final Optional<OPFItem> opfItem;
  /**
   * The OCF Package the resource being validated belongs to. Is absent for
   * single-file validations.
   */
  public final Optional<OCFPackage> ocf;
  /**
   * The cross-reference checker, absent for single-file validation.
   */
  public final Optional<XRefChecker> xrefChecker;
  /**
   * The src checker for media overlay text elements, absent for single-file
   * validation
   */
  public final Optional<OverlayTextChecker> overlayTextChecker;
  /**
   * The set of 'dc:type' values declared at the OPF level. Guaranteed non-null,
   * can be empty.
   */
  public final Set<PublicationType> pubTypes;
  /**
   * The set of properties associated to the resource being validated.
   */
  public final Set<Property> properties;

  private ValidationContext(ValidationContextBuilder builder)
  {
    Preconditions.checkState(builder.report != null, "report must be set");
    Preconditions.checkState(builder.resourceProvider != null || builder.ocf != null,
        "resource provider or ocf must be set");
    this.path = Strings.nullToEmpty(builder.path);
    this.mimeType = Strings.nullToEmpty(builder.mimeType);
    this.version = Optional.fromNullable(builder.version).or(EPUBVersion.Unknown);
    this.profile = Optional.fromNullable(builder.profile).or(EPUBProfile.DEFAULT);
    this.report = builder.report;
    this.locale = MoreObjects.firstNonNull(
        (report instanceof LocalizableReport) ? ((LocalizableReport) report).getLocale() : null,
        Locale.getDefault());
    this.featureReport = Optional.fromNullable(builder.featureReport).or(new FeatureReport());
    this.resourceProvider = (builder.resourceProvider != null) ? builder.resourceProvider
        : builder.ocf;
    this.opfItem = (builder.xrefChecker != null) ? builder.xrefChecker.getResource(builder.path)
        : Optional.<OPFItem> absent();
    this.ocf = Optional.fromNullable(builder.ocf);
    this.xrefChecker = Optional.fromNullable(builder.xrefChecker);
    this.overlayTextChecker = Optional.fromNullable(builder.overlayTextChecker);
    this.pubTypes = (builder.pubTypes != null) ? Sets.immutableEnumSet(builder.pubTypes)
        : EnumSet.noneOf(PublicationType.class);
    this.properties = builder.properties.build();
  }

  /**
   * Builds a new {@link ValidationContext} from various member objects or by
   * copying a parent context.
   *
   */
  public static final class ValidationContextBuilder
  {
    private String path = null;
    private String mimeType = null;
    private EPUBVersion version = null;
    private EPUBProfile profile = null;
    private Report report = null;
    private FeatureReport featureReport = null;

    private GenericResourceProvider resourceProvider = null;
    private OCFPackage ocf = null;
    private XRefChecker xrefChecker = null;
    private OverlayTextChecker overlayTextChecker = null;
    private Set<PublicationType> pubTypes = null;
    private ImmutableSet.Builder<Property> properties = ImmutableSet.<Property> builder();

    public ValidationContextBuilder()
    {
    }

    public ValidationContextBuilder(ValidationContext context)
    {
      copy(context);
    }

    public ValidationContextBuilder copy(ValidationContext context)
    {
      path = context.path;
      mimeType = context.mimeType;
      version = context.version;
      profile = context.profile;
      report = context.report;
      featureReport = context.featureReport;
      resourceProvider = context.resourceProvider;
      ocf = context.ocf.orNull();
      xrefChecker = context.xrefChecker.orNull();
      overlayTextChecker = context.overlayTextChecker.orNull();
      pubTypes = context.pubTypes;
      properties = ImmutableSet.<Property> builder().addAll(context.properties);
      return this;
    }

    public ValidationContextBuilder path(String path)
    {
      this.path = path;
      return this;
    }

    public ValidationContextBuilder mimetype(String mimetype)
    {
      this.mimeType = mimetype;
      return this;
    }

    public ValidationContextBuilder version(EPUBVersion version)
    {
      this.version = version;
      return this;
    }

    public ValidationContextBuilder profile(EPUBProfile profile)
    {
      this.profile = profile;
      return this;
    }

    public ValidationContextBuilder report(Report report)
    {
      this.report = report;
      return this;
    }

    public ValidationContextBuilder featureReport(FeatureReport featureReport)
    {
      this.featureReport = featureReport;
      return this;
    }

    public ValidationContextBuilder resourceProvider(GenericResourceProvider resourceProvider)
    {
      this.resourceProvider = resourceProvider;
      return this;
    }

    public ValidationContextBuilder ocf(OCFPackage ocf)
    {
      this.ocf = ocf;
      return this;
    }

    public ValidationContextBuilder xrefChecker(XRefChecker xrefChecker)
    {
      this.xrefChecker = xrefChecker;
      return this;
    }

    public ValidationContextBuilder overlayTextChecker(OverlayTextChecker overlayTextChecker)
    {
      this.overlayTextChecker = overlayTextChecker;
      return this;
    }

    public ValidationContextBuilder pubTypes(Set<PublicationType> pubTypes)
    {
      this.pubTypes = pubTypes;
      return this;
    }

    public ValidationContextBuilder properties(Set<Property> properties)
    {
      this.properties = ImmutableSet.builder();
      if (properties != null)
      {
        this.properties.addAll(properties);
      }
      return this;
    }

    public ValidationContextBuilder addProperty(Property property)
    {
      properties.add(Preconditions.checkNotNull(property));
      return this;
    }

    public ValidationContext build()
    {
      return new ValidationContext(this);
    }
  }

  /**
   * Utility to create {@link Predicate}s applying to {@link ValidationContext}
   * instances.
   *
   */
  public static final class ValidationContextPredicates
  {

    /**
     * Returns a predicate that evaluates to <code>true</code> if the given
     * property is declared in the context being tested.
     */
    public static Predicate<ValidationContext> hasProp(final Property property)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.properties.contains(property);
        }
      };
    }

    /**
     * Returns a predicate that evaluates to <code>true</code> if the given
     * publication <code>dc:type</code> is declared in the context being tested.
     */
    public static Predicate<ValidationContext> hasPubType(final PublicationType type)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.pubTypes.contains(type);
        }
      };
    }

    /**
     * Returns a predicate that evaluates to <code>true</code> if the context
     * being tested has the given media type.
     */
    public static Predicate<ValidationContext> mimetype(final String mimetype)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.mimeType.equals(mimetype);
        }
      };
    }

    /**
     * Returns a predicate that evaluates to <code>true</code> if the context
     * being tested has the given path.
     */
    public static Predicate<ValidationContext> path(final String path)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.path.equals(path);
        }
      };
    }

    /**
     * Returns a predicate that evaluates to <code>true</code> if the context
     * being tested declares the given validation profile.
     */
    public static Predicate<ValidationContext> profile(final EPUBProfile profile)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.profile.equals(profile);
        }
      };
    }

    /**
     * Returns a predicate that evaluates to <code>true</code> if the context
     * being tested declares the given EPUB version.
     */
    public static Predicate<ValidationContext> version(final EPUBVersion version)
    {
      return new Predicate<ValidationContext>()
      {
        @Override
        public boolean apply(ValidationContext input)
        {
          return input.version.equals(version);
        }
      };
    }

    private ValidationContextPredicates()
    {
    }
  }

}
