package cl.triskeledu.proveedor.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(
    name = "proveedor",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_proveedor_rut",   columnNames = "rut_proveedor"),
        @UniqueConstraint(name = "uk_proveedor_email", columnNames = "email")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Proveedor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "rut_proveedor", nullable = false, length = 12, unique = true)
    private String rutProveedor;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "email", nullable = false, length = 100, unique = true)
    private String email;

    @Column(name = "activo", nullable = false)
    @Builder.Default
    private Boolean activo = true;

    @OneToMany(mappedBy = "proveedor", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Contacto> contactos;

    @OneToMany(mappedBy = "proveedor", fetch = FetchType.LAZY)
    private List<OrdenCompra> ordenesCompra;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Proveedor)) return false;
        Proveedor that = (Proveedor) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
