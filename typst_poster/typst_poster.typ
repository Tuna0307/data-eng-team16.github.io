// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + departments),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Percentage Change in Prices], 
  // TODO: use Quarto's normalized metadata.
   authors: [Jiarui, Weixuan, Elsia, Haris, Shi Wei], 
   departments: [~], 
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/sit.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [AAI1001 AY24/25 Tri 2 Team Project], 

  // Any URL, like a link to the conference website.
   footer_url: [~], 

  // Emails of the authors.
   footer_email_ids: [Team 16], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)


= Introduction
<introduction>
The Singapore public-housing market has undergone pronounced shifts from 2020 to 2024, driven by demographic trends such as population ageing, household "rightsizing," and policy changes like the rollout of the 2-Room Flexi Scheme. Our project builds on a Straits Times graphic (STRAITS TIMES GRAPHICS, 2025) that maps the #strong[percentage change in HDB resale prices by flat type] over this period. Figure 1 illustrates the percentage change in resale prices by flat type—from 2020 to 2024—using data sourced from Data.gov.sg and Orangetee & Tie Research & Analytics. By comparing growth across 1‑room through Multi‑generation flats, this visualization highlights which segments have seen the strongest appreciation. We can build on this static snapshot by adding interactive filters, time-based x-axis and integrating transaction prices to deepen our insights into housing‑type–specific trends.

= Original Visualisation
<original-visualisation>
#figure([
#box(image("images/original.png"))
], caption: figure.caption(
position: bottom, 
[
Original Visualization
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- Flat types: Seven categories from 1‑room up to Multi‑generation \
- Horizontal bars: Length proportional to percent change; 2‑room (45.4 %) and 3‑room (41 %) highlighted in blue as the highest‑growth segments \
- Baseline marker: Vertical zero line to distinguish growth from decline (although all segments appreciated) \
- Annotations: Exact percentages labelled at bar ends for quick value retrieval \
- Color scheme: Grey for most categories, blue for top two to draw attention \
- Source & Credits: Chart: STRAITS TIMES GRAPHICS • Source: DATA.GOV.SG, ORANGETEE & TIE RESEARCH & ANALYTICS

= Critical Assessment of the Original Visualization
<critical-assessment-of-the-original-visualization>
+ #strong[Unordered Categories] \
  Flat types appear in an arbitrary sequence, forcing readers to search for the top and bottom performers rather than seeing them at a glance.

+ #strong[Uniform Grey Bars] \
  Except for two blue bars, all categories share the same grey, making it hard to discern above- vs.~below-average growth.

+ #strong[Lack of Volume Context] \
  Percentage changes can be misleading when based on very few transactions (e.g.~1-Room). No indication of deal counts appears.

+ #strong[Clipped & Inconsistent Labels] \
  Some annotations overlap the mean-line or the frame, and small-change bars carry labels that are too close to the axis cut-off.

+ #strong[Static, Print-Focused] \
  No interactive features to reveal exact values, drill into regional breakdowns, or display uncertainty around medians.

== Weaknesses
<weaknesses>
+ #strong[Lack of Temporal Granularity] \
  This chart only shows the aggregate 2020–2024 change. You can’t see when prices accelerated or cooled.

+ #strong[Legend Dependency for Value Lookup] \
  While exact percentages are labelled on the bars, the use of blue vs.~grey to "highlight" the top two segments has no accompanying legend or call‑out explaining #emph[why] those two are special.

+ #strong[Cluttered Axes and Distracting Gridlines] \
  The vertical gridlines are fairly prominent and, together with the zero‐line baseline, compete visually with the bars themselves.

+ #strong[Accessibility Concerns] \
  The grey vs.~blue contrast may be hard to distinguish for viewers with deuteranopia/protanopia. (No alternative texture or pattern is provided.)

+ #strong[Monotonous Color Schemes] \
  Aside from the two blue bars, all other categories use nearly identical greys, which makes it hard to pick out any mid‑ranked categories if you weren’t reading the labels.

+ #strong[Inefficient Legend Placement and Size] \
  There is no legend for interpreting the colour‐highlighting rule, and the source credits at the bottom bear a similar style weight to the chart itself, drawing attention away from the data.

#horizontalrule

= Suggested Improvements
<suggested-improvements>
+ #strong[Temporal Clarity] \
  Plotting x axis with years grants temporal granularity and insights to specific year.

+ #strong[Endpoint Annotations] \
  At 2024, each line is labeled with its percent increase (e.g., "\+47.8 %" for 3‑Room), eliminating the need for a separate legend lookup.

+ #strong[Clean Axes & Gridlinese] \
  The y‑axis uses compact currency labels; gridlines are subtly drawn to guide the eye without clutter.

+ #strong[Accessible Colors] \
  The enhanced plot is a multi‑line chart of #strong[Median HDB Resale Price by Flat Type (2020–2024)];. Each of the seven lines uses a distinct CUD color: 1‑Room (Sky Blue), 2‑Room (Vermilion), 3‑Room (Bluish Green), 4‑Room (Reddish Purple), 5‑Room (Orange), Executive (Yellow), Multi‑Generation (Blue)

+ #strong[Variety Colors] \
  Added a variety of color palettes to increase readability and improve visual appeal.

+ #strong[Improved Legend] \
  Positioned below, with enlarged line swatches and flat‑type names, making it easy to match colors to categories at a glance.

#horizontalrule

= Implementation for the Bar Graph
<implementation-for-the-bar-graph>
== Data Sources
<data-sources>
Weekly counts of HDB resale transactions were obtained from the Singapore Government’s open data portal (data.gov.sg). The dataset includes transaction dates, town, flat type, floor area, and resale price. Validation figures were sourced from a Straits Times news article covering the same topic.

== Software
<software>
tidyverse package was used for data manipulation and cleaning. lubridate package was used for handling date-time features. janitor package was used for initial data cleaning. plotly package was used for building the interactive web-based visualization.

= Improved visualisation
<improved-visualisation>
#figure([
#box(image("images/Improved Visualisation.png"))
], caption: figure.caption(
position: bottom, 
[
Improved Visualization
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Conclusion
<conclusion>
The enhanced multi‑line chart reveals that while Multi‑generation flats command the highest absolute resale values—surpassing S\$1 000 000 by 2024—it is the compact 2‑room units that appreciated the fastest (+47.8%), followed by 1‑room (+42%) and 3‑room flats (+39.9%). All flat types exhibited steady year‑on‑year growth, but percentage gains taper as unit size increases. These clear, accessible trends underscore robust demand for smaller, more affordable flats and equip policymakers and market participants with targeted insights into Singapore’s evolving HDB resale landscape.

= References
<references>
- #link("https://www.straitstimes.com/singapore/older-buyers-smaller-households-among-factors-driving-demand-for-smaller-flats")[STRAITS TIMES GRAPHICS. (2025, May 20). Older buyers, smaller households among factors driving demand for smaller flats \[Bar chart\]. The Straits Times.]
- DataGov.SG. (n.d.). HDB Resale Flat Prices \[Data set\]. https:\/\/data.gov.sg/dataset/hdb-resale-flat-prices
- Okabe, M., & Ito, K. (2008). Color Universal Design (CUD): How to make figures and presenta- tions that are friendly to Colorblind people. https:\/\/jfly.uni-koeln.de/color/
