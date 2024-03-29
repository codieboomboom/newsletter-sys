use crate::routes::{health_check, subscriptions};
use actix_web::dev::Server;
use actix_web::middleware::Logger;
use actix_web::{web, App, HttpServer};
use sqlx::PgPool;
use std::net::TcpListener;

pub fn run(listener: TcpListener, db_pool: PgPool) -> Result<Server, std::io::Error> {
    // Shadow and wrap the connection into a smart ptr
    let db_pool = web::Data::new(db_pool);
    // Capture connection from surrounding environment
    let server = HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .route(
                "/health_check",
                web::get().to(health_check::health_check_handler),
            )
            .route(
                "/subscriptions",
                web::post().to(subscriptions::subscribe_handler),
            )
            // Get ptr copy and attach it to the application state
            .app_data(db_pool.clone())
    })
    .listen(listener)?
    .run();
    Ok(server)
}
