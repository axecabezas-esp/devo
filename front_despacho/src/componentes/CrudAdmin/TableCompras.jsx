import { useState, useEffect } from "react";
import { Modal } from "./Modal";
import { FormDespacho } from "./FormDespacho";
import axios from "axios";

export const TableCompras = () => {
  const [ventas, setVentas] = useState([]);

  const compras = async () => {
    await axios.get("/api/ventas/", {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    }).then((response) => {
      console.log("Datos recibidos de Ventas:", response.data);
      
      // Si Spring Boot te está envolviendo la lista en una propiedad (por ejemplo 'content' o 'data')
      if (response.data && response.data.content) {
        setVentas(response.data.content);
      } else if (Array.isArray(response.data)) {
        setVentas(response.data);
      } else {
        console.error("Alerta: La API de ventas no retornó un Array directo.", response.data);
        setVentas([]); // Evita que se rompa asignando un array vacío por defecto
      }
    }).catch((error) => {
      console.error("Error al conectar con el microservicio de ventas:", error);
      setVentas([]);
    });
  };
  // Llamada a la función para obtener los datos cuando el componente se monta
  useEffect(() => {
    compras();
  }, []);

  //state que controla el modal
  const [openModal, setOpenModal] = useState(false);

  //state que abre el modal junto con la data del id seleccionado
  const [ventaSeleccionada, setVentaSeleccionada] = useState(null);
  const handleAbrirModal = (venta) => {
    setVentaSeleccionada(venta);
    setOpenModal(true);
  };

  return (
    <>
      <section className="grid text-center grid-cols-12 mb-8">
        <div className="col-span-12 flex justify-center">
          <div className="col-span-10 p-2 bg-white border border-gray-200 rounded-lg shadow dark:bg-white h-full overflow-hidden">
            <table className="table-fixed">
              <thead>
                <tr className="py-10">
                  <th className="pr-10">Orden de compra</th>
                  <th className="pr-10">direccion</th>
                  <th className="pr-10">fecha de compra</th>
                  <th className="pr-10">valor total</th>
                  <th className="pr-10"></th>
                </tr>
              </thead>
              <tbody>
                {Array.isArray(ventas) ? (
                  ventas
                    .filter((venta) => venta && !venta.despachoGenerado)
                    .map((venta) => (
                      <tr key={venta.idVenta}>
                        <td className="pr-10 py-10 items-center">
                          {venta.idVenta}
                        </td>
                        <td className="pr-10 py-10 items-center">
                          {venta.direccionCompra}
                        </td>
                        <td className="pr-10 py-10 items-center">
                          {venta.fechaCompra}
                        </td>
                        <td className="pr-10 py-10 items-center">
                          ${venta.valorCompra}
                        </td>
                        <td>
                          <button
                            onClick={() => handleAbrirModal(venta)}
                            className="py-1 bg-orange-200 px-8 rounded-xl shadow-md hover:bg-orange-300/70 transition-all duration-300 "
                          >
                            Generar Despacho
                          </button>
                        </td>
                      </tr>
                    ))
                ) : (
                  <tr>
                    <td colSpan="5" className="py-10 text-gray-500">
                      No se pudieron cargar las compras o el formato de datos es incorrecto.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </section>
      <Modal
        onClose={() => {
          setOpenModal(false);
        }}
        open={openModal}
      >
        {ventaSeleccionada && (
          <FormDespacho
            venta={ventaSeleccionada}
            onClose={() => {
              //onclose es un prop que pasa funciones al modal con el form abierto, por ende al cerrarse, se ejecutan esas 2 funciones
              setOpenModal(false), compras();
            }}
          />
        )}
      </Modal>
    </>
  );
};
