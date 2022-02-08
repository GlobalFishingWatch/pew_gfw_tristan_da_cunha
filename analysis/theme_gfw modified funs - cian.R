#' GFW standard ggplot chart theme
#'
#' @importFrom ggplot2 theme_minimal
#' @importFrom ggplot2 theme
#'
#' @export

theme_gfw_cian <- function() {
  
  # Use theme_minimal as base
  gfw_theme <- ggplot2::theme_minimal() +
    ggplot2::theme(
      # Chart panel and plot area
      panel.background = element_rect(fill = '#f7f7f7', color = NA),
      panel.grid.major = element_line(color = '#e6e7eb'),
      panel.grid.minor = element_line(color = '#e6e7eb'),
      panel.border = element_blank(),
      plot.background = element_rect(fill = '#f7f7f7', color = NA),
      # Titles
      plot.title = element_text(family = 'Roboto Black',
                                color = '#363c4c',
                                size = 10),
      plot.subtitle = element_text(family = 'Roboto',
                                   color = '#363c4c',
                                   size = 10),
      strip.text = element_text(family = 'Roboto',
                                color = '#363c4c',
                                face = "bold",
                                size = 10),
      # Legend
      legend.box = 'vertical',
      legend.title.align = 0.5,
      legend.text = element_text(family = 'Roboto',
                                 color = '#848b9b',
                                 size = 8),
      legend.title = element_text(family = 'Roboto',
                                  face = "bold",
                                  color = '#363c4c',
                                  size = 8),
      # Axis
      axis.title = element_text(family = 'Roboto',
                                face = "bold",
                                color = '#848b9b',
                                size = 8),
      axis.text = element_text(family = 'Roboto',
                               color = '#848b9b',
                               size = 6)
    )
}





#' GFW standard map theme
#'
#' @importFrom ggplot2 theme_minimal
#' @importFrom ggplot2 theme
#'
#' @export

theme_gfw_map_cian <- function(theme = 'dark') {
  
  # Use theme_minimal as base
  map_theme <- ggplot2::theme_minimal() +
    ggplot2::theme(
      # Chart panel
      panel.border = element_blank(),
      panel.background = element_rect(fill = '#f7f7f7', color = NA),
      # Legend
      legend.position = 'bottom',
      legend.box = 'vertical',
      legend.key.height = unit(3, 'mm'),
      legend.key.width = unit(20,'mm'),
      legend.title.align = 0.5,
      legend.text = element_text(family = 'Roboto',
                                 color = '#848b9b',
                                 size = 8),
      legend.title = element_text(family = 'Roboto',
                                  face = "bold",
                                  color = '#363c4c',
                                  size = 8),
      # Plot titles
      plot.title = element_text(family = 'Roboto',
                                face = "bold",
                                color = '#363c4c',
                                size = 10),
      plot.subtitle = element_text(family = 'Roboto',
                                   color = '#363c4c',
                                   size = 10),
      # Axes
      axis.title = element_blank(),
      axis.text = element_text(family = 'Roboto',
                               color = '#848b9b',
                               size = 6)
    ) +
    # Add backgrond theme using dark or light background
    if(theme == 'dark'){
      ggplot2::theme(
        panel.background = element_rect(fill = '#0a1738', color = NA),
        panel.grid.major = element_line(color = '#0a1738'),
        panel.grid.minor = element_line(color = '#0a1738')
      )
    } else if (theme == 'light'){
      ggplot2::theme(
        panel.background = element_rect(fill = '#ffffff', color = NA),
        panel.grid.major = element_line(color = '#ffffff'),
        panel.grid.minor = element_line(color = '#ffffff')
      )
    }
}

