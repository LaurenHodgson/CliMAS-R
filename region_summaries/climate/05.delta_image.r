library(SDMTools);library(plotrix);library(maptools)

source('/home/jc148322/scripts/libraries/cool_functions.r')

out.dir='/home/jc148322/AP02/climate.summaries/downloadable.data/';dir.create(out.dir)
delta.dir='/home/jc148322/AP02/climate.summaries/asciis/'
layer.dir='/home/jc148322/AP02/climate.summaries/region_layers/'
base.asc = read.asc.gz('/home/jc165798/Climate/CIAS/Australia/5km/baseline.76to05/base.asc.gz') #read in the base asc file
#read in asciis
pos=make.pos(base.asc)
blank.asc=base.asc; blank.asc[which(is.na(blank.asc))]=0

clim.vars=c('temperature','rainfall')

for (clim.var in clim.vars) {
	asc.dir=paste(delta.dir,clim.var,'/',sep=''); setwd(asc.dir)
	asciis=list.files()
	files=gsub('.asc.gz','',asciis)
	tfiles1=grep('RCP45',files,value=T);tfiles2=grep('RCP85',files,value=T)
	files=c(tfiles1,tfiles2)

	for (i in 1:length(files)) {cat(files[i],'\n')
		tasc=read.asc.gz(paste(files[i],'.asc.gz',sep=''))
		if (clim.var==clim.vars[2]) {tasc[which(tasc>500)]=500; tasc[which(tasc<=-500)]=-500; }
		assign(files[i],tasc) #saves ascii in memory as name of file. ie. RCP3PD.10th
		pos[,files[i]]=extract.data(cbind(pos$lon,pos$lat),get(files[i]))
	}

	vois=c('State','NRM','IBRA')
	# for (clim.var in clim.vars){ cat(clim.var, '\n')

	for (voi in vois) {cat (voi, '\n')
		setwd(out.dir)
		#identify regions
		regions=list.files(pattern=voi)
		
		
		pos[,voi]=extract.data(cbind(pos$lon,pos$lat),read.asc(paste(layer.dir, voi,'.asc',sep='')))

		if (voi==vois[1]) { polys=readShapePoly(paste(layer.dir,'Shapefile/STE11aAust.shp',sep=''));
							polys@data[,voi]=polys@data$STATE_NAME ;
							polys@data$regioncode=polys@data$STATE_CODE}
		if (voi==vois[2]) { polys=readShapePoly(paste(layer.dir,'Shapefile/NRM_Regions_2010.shp',sep=''));
							polys@data[,voi]=polys@data$NRM_REGION;
							polys@data$regioncode=c(0:63)}
		if (voi==vois[3]) { polys=readShapePoly(paste(layer.dir,'Shapefile/IBRA7_regions.shp',sep=''));
							polys@data[,voi]=polys@data$REG_NAME_7;
							polys@data$regioncode=polys@data$OBJECTID}
							
		

		for (region in regions) {cat (region, '\n')
			region.dir=paste(out.dir, region,'/',sep='');setwd(region.dir)
			region.name=sub('[^_]+_','',region); #eat everything before the first underscore, and the first underscore
			region.name=gsub('_',' ',region.name)
			region.code=polys@data$regioncode[which(polys@data[,voi]==region.name)]
			
			if (clim.var==clim.vars[1]) {cols=colorRampPalette(c("#A50026","#D73027","#F46D43","#FDAE61","#FEE090","#FFFFBF","#f0f9dc","#E0F3F8"))(100); cols=cols[100:1] ; zlim=c(-1,7) }
			if (clim.var==clim.vars[2]) { cols=colorRampPalette(c('#6E3D27','#A3451C','#d08d0e','#FFD600','#ffff63','#cbff61','#5bd857','#39BA6A','#2a895f','#1B5B55'))(100); zlim=c(-500,500) }

			
			tpoly=polys[which(polys@data[,voi]==region.name),]

			
			pos$region=NA
			pos$region[which(pos[,voi]==region.code)]=1

			# pos$mask=1
			# pos$mask[which(pos[,voi]==region)]=NA
			# region.mask=make.asc(pos$mask)
			
			assign.list(min.lon,max.lon,min.lat,max.lat) %=% fixed.zoom(pos$region, 1, 2)
			
			if (max.lat>=-12 & min.lat<=-36.5 |
				max.lon>=148 & min.lon<=120 ) { 
				xlim=c(min(pos$lon),max(pos$lon)); 
				ylim=c(min(pos$lat),max(pos$lat))

			}else{ 
				xlim=c(min.lon,max.lon); 
				ylim=c(min.lat,max.lat)
			}

			
			png(paste(region.dir,'delta.',clim.var, '.png',sep=''),width=dim(base.asc)[1]*2+30, height=dim(base.asc)[2]*3+100, units='px', pointsize=20, bg='white')
				par(mar=c(4,2,0,2),mfrow=c(2,3),cex=1,oma=c(0,3,5,1))
						mat = matrix(c (1,1,1,1,4,4,4,4,
										1,1,1,1,4,4,4,4,
										1,1,1,1,4,4,4,4,
										2,2,2,2,5,5,5,5,
										2,2,2,2,5,5,5,5,
										2,2,2,2,5,5,5,5,
										3,3,3,3,6,6,6,6,
										3,3,3,3,6,6,6,6,
										3,3,3,3,6,6,6,6,
										7,8,8,8,8,8,8,8),nr=10,nc=8,byrow=TRUE) #create a layout matrix for images
					layout(mat) #call layout as defined above

				for (i in 1:6) {
					
					image(blank.asc, ann=FALSE,axes=FALSE,col='white',xlim=xlim,ylim=ylim)
					rect(100,-50,165,-5, col='grey90')
					image(get(files[i]), ann=FALSE,axes=FALSE,col=cols, zlim=zlim, add=TRUE)
					plot(tpoly,add=TRUE,border='grey20',lwd=2)
					
					if (i==1) { mtext('Low (RCP4.5)', line=1,side=3,cex=2,font=2)
									mtext('10th percentile', line=1,side=2, cex=1.5, font=3)}
					if (i==2) { mtext('50th percentile', line=1,side=2, cex=1.5, font=3)}
					if (i==3) { mtext('90th percentile', line=1,side=2, cex=1.5, font=3)
								margin.legend(x=0,y=-5,w=50,h=5,cols=cols,text.limits=round(zlim),cex=1)} 
								
					if (i==4) { mtext('High (RCP8.5)', line=1,side=3,cex=2,font=2)}
				
				}
				par(mar=c(1,1,0,1))
				image(base.asc, ann=FALSE,axes=FALSE,col='grey70')
				plot(tpoly,add=TRUE,col="black",border="black")
				
				plot(1:20,axes=FALSE, ann=FALSE,type = "n")
				text(0.2, 17, paste('Figure 1: Change in annual mean ',clim.var,' for a low and high emissions scenario in 2085.',sep=''), cex=2,pos=4)
				text(0.2, 13, 'The 10th, 50th and 90th percentiles show variation between 18 GCMs.', cex=2,pos=4)
				text(0.2, 9, 'The middle model (50th percentile) of the high emissions scenario is our best estimate of the current trajectory.', cex=2,pos=4)
				
				text(0.2, 3, paste('Management region: ',region.name,sep=''), cex=2,pos=4)
				
			dev.off()
			
		}
			
	}
}
 			