package cl.triskeledu.proveedor.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "contacto")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Contacto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rut_proveedor", referencedColumnName = "rut_proveedor", nullable = false)
    private Proveedor proveedor;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "telefono", nullable = false, length = 20)
    private String telefono;

    @Column(name = "cargo", nullable = true, length = 50)
    private String cargo;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Contacto)) return false;
        Contacto that = (Contacto) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
