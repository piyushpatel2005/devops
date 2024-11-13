# make Builder phase
FROM node:alpine as builder

WORKDIR '/app'
COPY package.json .

RUN npm install
COPY . .
# will create /app/build inside this container
RUN npm run build 

# this will be Run phase
FROM nginx 
# Expose port 80
EXPOSE 80
# Copy the build content to nginx
COPY --from=builder /app/build /usr/share/nginx/html

