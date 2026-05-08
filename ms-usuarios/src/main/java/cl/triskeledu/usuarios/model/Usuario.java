package cl.triskeledu.usuarios.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(
    name = "usuario",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_usuario_email", columnNames = "email")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "email", nullable = false, length = 100, unique = true)
    private String email;

    @Column(name = "contrasena", nullable = false, length = 255)
    private String contrasena;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false, length = 20)
    @Builder.Default
    private Rol rol = Rol.cliente;

    @Column(name = "activo", nullable = false)
    @Builder.Default
    private Boolean activo = true;

    @OneToOne(mappedBy = "usuario", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Perfil perfil;

    @OneToMany(mappedBy = "usuario", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Direccion> direcciones;

    public enum Rol {
        cliente, admin, bodeguero, soporte
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Usuario)) return false;
        Usuario that = (Usuario) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
