.summarygridpixels<-function(object, var, fun=mean, freq=NULL, dates = NULL, months = NULL, pixels = FALSE, ...) {
  VARS = c("MeanTemperature", "MinTemperature","MaxTemperature", "Precipitation",
           "MeanRelativeHumidity", "MinRelativeHumidity", "MaxRelativeHumidity",
           "Radiation", "WindSpeed", "WindDirection", "PET")
  var = match.arg(var, VARS)
  if(inherits(object,"SpatialPixelsMeteorology") || inherits(object,"SpatialGridMeteorology")) {
    gt = object@grid
    nx = gt@cells.dim[1]
    ny = gt@cells.dim[2]
    gdates = object@dates
    crs = object@proj4string
    points = as(object, "SpatialPoints")
    npoints = length(points)
    cat(paste("  Summarizing ", var, " in ", npoints," pixels...\n", sep=""))
    dfvec = vector("list",npoints)
    pb = txtProgressBar(0, npoints, 0, style = 3)
    for(i in 1:npoints) {
      setTxtProgressBar(pb, i)
      vals = numeric(0)
      for(j in 1:length(gdates)) {
        vals = c(vals, object@data[[j]][i, var])
      }
      names(vals) = as.character(gdates)
      dfvec[[i]] = .summaryvarpoint(vals, fun = fun, freq=freq, dates = dates, months = months,...)
    }
    cat("\n")
  } else {
    file = object
    ncin = .openreadNetCDF(file)
    gt = .readgridtopologyNetCDF(ncin)
    gdates = .readdatesNetCDF(ncin)
    nx = ncin$dim$X$len
    ny = ncin$dim$Y$len
    crs = .readCRSNetCDF(ncin)
    points = SpatialPoints(coordinates(gt), proj4string = crs)
    npoints = nx*ny  
    cat(paste("  Summarizing ", var, " in ", npoints," grid pixels...\n", sep=""))
    dfvec = vector("list",npoints)
    cnt = 1
    pb = txtProgressBar(0, npoints, 0, style = 3)
    sel = rep(TRUE, npoints)
    for(j in 1:ny) {
      for(i in 1:nx) {
        setTxtProgressBar(pb, cnt)
        vals = .readvardatapixel(ncin, ncin$var[[var]], i,j)
        names(vals) = as.character(gdates)
        if(sum(!is.na(vals))==0) sel[cnt] = FALSE
        dfvec[[cnt]] = .summaryvarpoint(vals, fun = fun, freq=freq, dates = dates, months = months,...)
        cnt = cnt+1
      }
    }  
    cat("\n")
    if(pixels) {
      #Remove empty grid cells
      cat(paste("  Removing ", sum(!sel), " empty grid pixels...\n", sep=""))
      points = points[sel]
      dfvec = dfvec[sel]
      npoints = length(points)
    }
  }
  
  noutvars = length(dfvec[[1]])
  dfout = data.frame(matrix(NA,nrow=npoints, ncol=noutvars))
  outvarnames = names(dfvec[[1]])
  if(!is.null(outvarnames)) names(dfout) = outvarnames
  cat(paste("  Arranging output...\n", sep=""))
  pb = txtProgressBar(0, npoints, 0, style = 3)
  for(i in 1:npoints) {
    setTxtProgressBar(pb, i)
    dfout[i,] = as.numeric(dfvec[[i]])
  }
  
  if(!pixels) {
    return(SpatialGridDataFrame(gt,dfout, proj4string=crs))
  } else {
    return(SpatialPixelsDataFrame(points=points, data=dfout, proj4string=crs, grid = gt))
  }
}
summarypixels<-function(pixels, var, fun=mean, freq=NULL, dates = NULL, months = NULL, ...) {
  if(!inherits(pixels,"SpatialPixelsMeteorology") && !inherits(pixels,"character")) stop("'pixels' has to be of class 'SpatialPixelsMeteorology' or a 'character'.")
  return(.summarygridpixels(pixels, var=var, fun=fun, freq=freq, dates=dates, months=months, pixels = TRUE, ...))
}
summarygrid<-function(grid, var, fun=mean, freq=NULL, dates = NULL, months = NULL, ...) {
  if(!inherits(grid,"SpatialGridMeteorology") && !inherits(grid,"character")) stop("'grid' has to be of class 'SpatialPixelsMeteorology' or a 'character'.")
  return(.summarygridpixels(grid, var=var, fun=fun, freq=freq, dates=dates, months=months, pixels = FALSE, ...))
}